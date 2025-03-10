import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gas_eip1559.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/components/token_transfer_amount.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/transactions/base_token.dart';
import 'package:zilpay/src/rust/models/transactions/evm.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/src/rust/models/transactions/scilla.dart';
import 'package:zilpay/state/app_state.dart';

void showConfirmTransactionModal({
  required BuildContext context,
  required TransactionRequestInfo tx,
  required String to,
  required String amount,
  required int tokenIndex,
  ColorsInfo? colors,
  required Function(HistoricalTransactionInfo) onConfirm,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => _ConfirmTransactionContent(
      tx: tx,
      tokenIndex: tokenIndex,
      amount: amount,
      to: to,
      colors: colors,
      onConfirm: (tx) {
        onConfirm(tx);
        if (onDismiss != null) {
          onDismiss();
        }
      },
    ),
  ).then((_) {
    if (onDismiss != null) {
      onDismiss();
    }
  });
}

class _ConfirmTransactionContent extends StatefulWidget {
  final TransactionRequestInfo tx;
  final String to;
  final int tokenIndex;
  final String amount;
  final ColorsInfo? colors;
  final Function(HistoricalTransactionInfo) onConfirm;

  const _ConfirmTransactionContent({
    required this.tx,
    required this.amount,
    required this.to,
    required this.tokenIndex,
    this.colors,
    required this.onConfirm,
  });

  @override
  State<_ConfirmTransactionContent> createState() =>
      _ConfirmTransactionContentState();
}

class _ConfirmTransactionContentState
    extends State<_ConfirmTransactionContent> {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _authService = AuthService();
  late final AuthGuard _authGuard;
  RequiredTxParamsInfo _txParamsInfo = RequiredTxParamsInfo(
    gasPrice: BigInt.zero,
    maxPriorityFee: BigInt.zero,
    feeHistory: GasFeeHistoryInfo(
      maxFee: BigInt.zero,
      priorityFee: BigInt.zero,
      baseFee: BigInt.zero,
    ),
    txEstimateGas: BigInt.zero,
    blobBaseFee: BigInt.zero,
    nonce: BigInt.zero,
  );
  bool _loading = false;
  String? _error;
  BigInt _maxPriorityFee = BigInt.zero;
  BigInt _gasPrice = BigInt.zero;
  bool _obscurePassword = true;
  Timer? _timerPooling;

  bool get isEVM => widget.tx.evm != null;
  bool get isScilla => widget.tx.scilla != null;

  @override
  void initState() {
    super.initState();
    _authGuard = context.read<AuthGuard>();
    _initGasPolling();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _timerPooling?.cancel();
    super.dispose();
  }

  bool get _isDisabled {
    return (_txParamsInfo.gasPrice == BigInt.zero &&
            _txParamsInfo.maxPriorityFee == BigInt.zero &&
            _txParamsInfo.txEstimateGas == BigInt.zero) ||
        _loading;
  }

  void _initGasPolling() {
    _fetchGasFee(true);
    final appState = context.read<AppState>();
    final chainHash = appState.account?.chainHash ?? BigInt.zero;
    int diffBlockTime =
        appState.getChain(chainHash)?.diffBlockTime.toInt() ?? 20;

    if (diffBlockTime < 10) {
      diffBlockTime = 10;
    }

    _timerPooling = Timer.periodic(
        Duration(seconds: diffBlockTime), (_) => _fetchGasFee(false));
  }

  Future<void> _fetchGasFee(bool initial) async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    try {
      if (initial) _error = null;
      final gas = await caclGasFee(
        params: widget.tx,
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );
      if (mounted) {
        setState(() => _txParamsInfo = gas);
      }
    } catch (e) {
      debugPrint('Gas fee error: $e');
      if (initial && mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  TransactionRequestInfo _prepareTx() => isEVM
      ? TransactionRequestInfo(
          metadata: widget.tx.metadata,
          evm: TransactionRequestEVM(
            nonce: _txParamsInfo.nonce,
            from: widget.tx.evm!.from,
            to: widget.tx.evm!.to,
            value: widget.tx.evm!.value,
            data: widget.tx.evm!.data,
            chainId: widget.tx.evm!.chainId,
            accessList: widget.tx.evm!.accessList,
            blobVersionedHashes: widget.tx.evm!.blobVersionedHashes,
            maxFeePerBlobGas: widget.tx.evm!.maxFeePerBlobGas,
            maxPriorityFeePerGas: _maxPriorityFee,
            gasLimit: _txParamsInfo.txEstimateGas,
            gasPrice: _gasPrice,
            maxFeePerGas: (_txParamsInfo.feeHistory.baseFee * BigInt.two) +
                _maxPriorityFee,
          ),
        )
      : TransactionRequestInfo(
          metadata: widget.tx.metadata,
          scilla: TransactionRequestScilla(
            chainId: widget.tx.scilla!.chainId,
            nonce: _txParamsInfo.nonce + BigInt.one,
            gasPrice: _gasPrice,
            gasLimit: widget.tx.scilla!.gasLimit,
            toAddr: widget.tx.scilla!.toAddr,
            amount: widget.tx.scilla!.amount,
            code: widget.tx.scilla!.code,
            data: widget.tx.scilla!.data,
          ),
        );

  Future<bool> _authenticate() async => _authService.authenticate(
      allowPinCode: true, reason: 'Please authenticate');

  Future<HistoricalTransactionInfo?> _signAndSend(
      AppState appState, TransactionRequestInfo tx) async {
    final device = DeviceInfoService();
    final identifiers = await device.getDeviceIdentifiers();
    final wallet = appState.wallet!;
    final walletIndex = BigInt.from(appState.selectedWallet);
    final accountIndex = wallet.selectedAccount;

    if (wallet.authType != AuthMethod.none.name) {
      if (!await _authenticate()) return null;
      final session =
          await _authGuard.getSession(sessionKey: wallet.walletAddress);
      return await signSendTransactions(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        identifiers: identifiers,
        tx: tx,
        sessionCipher: session,
      );
    } else {
      return await signSendTransactions(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        identifiers: identifiers,
        tx: tx,
        password: _passwordController.text,
      );
    }
  }

  bool _checkBalance(AppState appState) {
    try {
      final token = appState.wallet!.tokens[widget.tokenIndex];
      final balance =
          BigInt.parse(token.balances[appState.wallet!.selectedAccount] ?? '0');
      return balance >= toWei(widget.amount, token.decimals);
    } catch (_) {
      return false;
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.currentTheme;

    final backgroundColor =
        _parseColor(widget.colors?.background) ?? theme.cardBackground;
    final primaryColor =
        _parseColor(widget.colors?.primary) ?? theme.primaryPurple;
    final secondaryColor = _parseColor(widget.colors?.secondary) ??
        theme.textSecondary.withValues(alpha: 0.5);
    final textColor = _parseColor(widget.colors?.text) ?? theme.textSecondary;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.modalBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/warning.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                  theme.danger, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: theme.danger, fontSize: 14))),
                          ],
                        ),
                      ),
                    _buildTokenLogo(appState, primaryColor),
                    const SizedBox(height: 4),
                    _buildTransferDetails(appState, textColor, secondaryColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GasEIP1559(
                        timeDiffBlock:
                            appState.chain?.diffBlockTime.toInt() ?? 10,
                        txParamsInfo: _txParamsInfo,
                        disabled: _isDisabled,
                        onChangeGasPrice: (gasPrice) =>
                            setState(() => _gasPrice = gasPrice),
                        onChangeMaxPriorityFee: (maxPriorityFee) =>
                            setState(() => _maxPriorityFee = maxPriorityFee),
                        primaryColor: primaryColor,
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                      ),
                    ),
                    if (appState.wallet!.authType == AuthMethod.none.name)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SmartInput(
                          key: _passwordInputKey,
                          controller: _passwordController,
                          hint: 'Password',
                          fontSize: 18,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: primaryColor,
                          disabled: _isDisabled,
                          obscureText: _obscurePassword,
                          rightIconPath: _obscurePassword
                              ? 'assets/icons/close_eye.svg'
                              : 'assets/icons/open_eye.svg',
                          onRightIconTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          textColor: textColor,
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SwipeButton(
                        text: _error != null ? 'Unable to confirm' : 'Confirm',
                        disabled: _isDisabled,
                        onSwipeComplete: () async {
                          setState(() => _loading = true);
                          try {
                            if (!_checkBalance(appState)) {
                              throw Exception('Insufficient balance');
                            }
                            final tx = _prepareTx();
                            HistoricalTransactionInfo? sendedTx =
                                await _signAndSend(appState, tx);

                            if (mounted && sendedTx != null) {
                              widget.onConfirm(sendedTx);
                            }
                          } catch (e) {
                            setState(() => _error = e.toString());
                          } finally {
                            setState(() => _loading = false);
                          }
                        },
                        backgroundColor: theme.primaryPurple,
                        textColor: theme.buttonText,
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.viewInsetsOf(context).bottom > 0
                            ? 16
                            : 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenLogo(AppState state, Color primaryColor) {
    const imageSize = 54.0;
    final theme = state.currentTheme;
    final icon = widget.tx.metadata.icon;

    if (icon != null) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: primaryColor.withValues(alpha: 0.1), width: 2),
        ),
        child: ClipOval(
            child: AsyncImage(
                url: icon,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain)),
      );
    }

    try {
      final token = state.wallet!.tokens
          .firstWhere((t) => t.symbol == widget.tx.metadata.tokenInfo?.symbol);
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: primaryColor.withValues(alpha: 0.1), width: 2),
        ),
        child: ClipOval(
          child: AsyncImage(
            url: processTokenLogo(token, theme.value),
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTransferDetails(
      AppState appState, Color textColor, Color secondaryColor) {
    try {
      final ftoken = appState.wallet!.tokens[widget.tokenIndex];
      BaseTokenInfo token = widget.tx.metadata.tokenInfo ??
          BaseTokenInfo(
              value: '', symbol: ftoken.symbol, decimals: ftoken.decimals);

      final signer = appState.account ?? (throw Exception('No active account'));
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TokenTransferAmount(
          fromAddress: signer.addr,
          fromName: signer.name,
          toAddress: widget.to,
          amount: widget.amount,
          symbol: token.symbol,
          textColor: textColor,
          secondaryColor: secondaryColor,
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed to load transfer details');
      return const SizedBox.shrink();
    }
  }
}
