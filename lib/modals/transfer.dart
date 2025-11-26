import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gas_eip1559.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/components/token_transfer_amount.dart';
import 'package:zilpay/components/transaction_amount_display.dart';
import 'package:zilpay/ledger/ledger_connector.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/modals/edit_gas_dialog.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/transactions/base_token.dart';
import 'package:zilpay/src/rust/models/transactions/evm.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/src/rust/models/transactions/scilla.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/utils/utils.dart';

void showConfirmTransactionModal({
  required BuildContext context,
  required TransactionRequestInfo tx,
  required String to,
  required String amount,
  required FTokenInfo token,
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
      token: token,
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
  final FTokenInfo token;
  final String amount;
  final ColorsInfo? colors;
  final Function(HistoricalTransactionInfo) onConfirm;

  const _ConfirmTransactionContent({
    required this.tx,
    required this.amount,
    required this.to,
    required this.token,
    this.colors,
    required this.onConfirm,
  });

  @override
  State<_ConfirmTransactionContent> createState() =>
      _ConfirmTransactionContentState();
}

class _ConfirmTransactionContentState
    extends State<_ConfirmTransactionContent> {
  late final bool _isLedgerWallet;
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
  BigInt _totalFee = BigInt.zero;
  bool _obscurePassword = true;
  Timer? _timerPooling;
  Timer? _scanTimeout;

  bool get isEVM => widget.tx.evm != null;
  bool get isScilla => widget.tx.scilla != null;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _authGuard = context.read<AuthGuard>();
    _initGasPolling();
    _isLedgerWallet = appState.selectedWallet != -1 &&
        appState.wallets[appState.selectedWallet].walletType
            .contains(WalletType.ledger.name);

    if (_isLedgerWallet) {
      appState.ledgerViewController.scan();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _timerPooling?.cancel();
    _scanTimeout?.cancel();

    if (_isLedgerWallet && context.mounted) {
      final appState = context.read<AppState>();
      appState.ledgerViewController.stopScan();
    }

    super.dispose();
  }

  bool get _isDisabled {
    return (_txParamsInfo.gasPrice == BigInt.zero &&
            _txParamsInfo.maxPriorityFee == BigInt.zero &&
            _txParamsInfo.txEstimateGas == BigInt.zero) ||
        _loading;
  }

  Future<void> _onDeviceLedgerOpen(DiscoveredDevice device) async {
    final appState = context.read<AppState>();
    await appState.ledgerViewController.open(device);
    setState(() {});
  }

  void _initGasPolling() {
    _fetchGasFee(true);
    final appState = context.read<AppState>();
    final chainHash = appState.account?.chainHash ?? BigInt.zero;
    int diffBlockTime =
        appState.getChain(chainHash)?.diffBlockTime.toInt() ?? 20;

    if (diffBlockTime < 2) {
      diffBlockTime = 2;
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

  TransactionRequestInfo _prepareTx(BigInt adjustedAmount) {
    if (isEVM) {
      return TransactionRequestInfo(
        metadata: widget.tx.metadata,
        evm: TransactionRequestEVM(
          nonce: _txParamsInfo.nonce,
          from: widget.tx.evm!.from,
          to: widget.tx.evm!.to,
          value: adjustedAmount.toString(),
          data: widget.tx.evm!.data,
          chainId: widget.tx.evm!.chainId,
          accessList: widget.tx.evm!.accessList,
          blobVersionedHashes: widget.tx.evm!.blobVersionedHashes,
          maxFeePerBlobGas: widget.tx.evm!.maxFeePerBlobGas,
          maxPriorityFeePerGas: _maxPriorityFee,
          gasLimit: _txParamsInfo.txEstimateGas,
          gasPrice:
              _txParamsInfo.feeHistory.maxFee > BigInt.zero ? null : _gasPrice,
          maxFeePerGas:
              (_txParamsInfo.feeHistory.baseFee * BigInt.two) + _maxPriorityFee,
        ),
      );
    } else if (isScilla) {
      return TransactionRequestInfo(
        metadata: widget.tx.metadata,
        scilla: TransactionRequestScilla(
          chainId: widget.tx.scilla!.chainId,
          nonce: _txParamsInfo.nonce + BigInt.one,
          gasPrice: _gasPrice,
          gasLimit: _txParamsInfo.txEstimateGas,
          toAddr: widget.tx.scilla!.toAddr,
          amount: adjustedAmount,
          code: widget.tx.scilla!.code,
          data: widget.tx.scilla!.data,
        ),
      );
    } else {
      throw Exception('Unsupported transaction type');
    }
  }

  Future<bool> _authenticate() async => _authService.authenticate(
      allowPinCode: true, reason: AppLocalizations.of(context)!.authReason);

  Future<HistoricalTransactionInfo?> _signAndSendLedger(
    AppState appState,
    TransactionRequestInfo tx,
  ) async {
    final accountIndex = appState.wallet!.selectedAccount.toInt();
    final account = appState.account;
    final sig = await appState.ledgerViewController.signTransaction(
      transaction: tx,
      walletIndex: appState.selectedWallet,
      accountIndex: accountIndex,
      account: account!,
    );

    return await sendSignedTransactions(
      tx: tx,
      sig: sig,
      walletIndex: appState.selectedWallet,
      accountIndex: accountIndex,
    );
  }

  Future<HistoricalTransactionInfo?> _signAndSend(
    AppState appState,
    TransactionRequestInfo tx,
  ) async {
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
    final l10n = AppLocalizations.of(context)!;

    final backgroundColor =
        _parseColor(widget.colors?.background) ?? theme.cardBackground;
    final primaryColor =
        _parseColor(widget.colors?.primary) ?? theme.primaryPurple;
    final secondaryColor = _parseColor(widget.colors?.secondary) ??
        theme.textSecondary.withValues(alpha: 0.5);
    final textColor = _parseColor(widget.colors?.text) ?? theme.textSecondary;

    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

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
                    if (_isLedgerWallet) ...[
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        child: LedgerConnector(
                          controller: appState.ledgerViewController,
                          onOpen: _onDeviceLedgerOpen,
                        ),
                      ),
                    ],
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
                                    style: theme.bodyText2.copyWith(
                                        color: theme.danger))),
                          ],
                        ),
                      ),
                    _buildTokenLogo(appState, primaryColor),
                    const SizedBox(height: 4),
                    _buildTransferDetails(appState, textColor, secondaryColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          GasEIP1559(
                            timeDiffBlock:
                                appState.chain?.diffBlockTime.toInt() ?? 10,
                            txParamsInfo: _txParamsInfo,
                            disabled: _isDisabled,
                            onChangeGasPrice: (gasPrice) =>
                                setState(() => _gasPrice = gasPrice),
                            onChangeMaxPriorityFee: (maxPriorityFee) =>
                                setState(
                                    () => _maxPriorityFee = maxPriorityFee),
                            onTotalFeeChange: (totalFee) =>
                                setState(() => _totalFee = totalFee),
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              splashFactory: NoSplash.splashFactory,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => EditGasDialog(
                                    txParamsInfo: _txParamsInfo,
                                    initialGasPrice: _gasPrice,
                                    initialNonce: _txParamsInfo.nonce,
                                    initialMaxPriorityFee: _maxPriorityFee,
                                    data: widget.tx.evm?.data != null
                                        ? bytesToHex(widget.tx.evm!.data!)
                                        : null,
                                    initialGasLimit:
                                        _txParamsInfo.txEstimateGas,
                                    onSave: (
                                      gasPrice,
                                      maxPriorityFee,
                                      gasLimit,
                                      nonce,
                                    ) {
                                      if (!mounted) return;

                                      setState(() {
                                        _gasPrice = gasPrice;
                                        _maxPriorityFee = maxPriorityFee;

                                        _txParamsInfo = RequiredTxParamsInfo(
                                          gasPrice: _txParamsInfo.gasPrice,
                                          maxPriorityFee:
                                              _txParamsInfo.maxPriorityFee,
                                          feeHistory: _txParamsInfo.feeHistory,
                                          txEstimateGas: gasLimit,
                                          blobBaseFee:
                                              _txParamsInfo.blobBaseFee,
                                          nonce: _txParamsInfo.nonce,
                                        );

                                        final BigInt baseFee =
                                            _txParamsInfo.feeHistory.baseFee;
                                        BigInt newTotalFee;

                                        if (baseFee != BigInt.zero) {
                                          final maxFeePerGas =
                                              baseFee + maxPriorityFee;
                                          newTotalFee = gasLimit * maxFeePerGas;
                                        } else {
                                          newTotalFee = gasLimit * gasPrice;
                                        }
                                        _totalFee = newTotalFee;
                                      });
                                    },
                                    primaryColor: primaryColor,
                                    textColor: textColor,
                                    secondaryColor: secondaryColor,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 8, right: 8, bottom: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/edit.svg',
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                        theme.warning,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.confirmTransactionEditGasButtonText,
                                      style: theme.labelMedium.copyWith(
                                        color: theme.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (appState.wallet!.authType == AuthMethod.none.name &&
                        !_isLedgerWallet)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SmartInput(
                          key: _passwordInputKey,
                          controller: _passwordController,
                          hint: l10n.confirmTransactionContentPasswordHint,
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
                        text: _error != null
                            ? l10n.confirmTransactionContentUnableToConfirm
                            : l10n.confirmTransactionContentConfirm,
                        disabled: _isDisabled ||
                            (_isLedgerWallet &&
                                appState.ledgerViewController
                                        .connectedTransport ==
                                    null),
                        onSwipeComplete: () async {
                          setState(() => _loading = true);
                          try {
                            final amount = toDecimalsWei(
                              widget.amount,
                              widget.token.decimals,
                            );
                            final fee = _totalFee;
                            BigInt adjustedTokenValue = amount;
                            bool isNativeTx =
                                (widget.tx.evm?.data?.isEmpty ?? true) &&
                                    (widget.tx.scilla?.data.isEmpty ?? true);
                            final balance = BigInt.parse(widget.token.balances[
                                    appState.wallet!.selectedAccount] ??
                                '0');

                            if (isNativeTx && amount == balance) {
                              adjustedTokenValue = amount - fee;
                            }

                            if (!isNativeTx && isScilla) {
                              adjustedTokenValue =
                                  widget.tx.scilla?.amount ?? BigInt.zero;
                            } else if (!widget.token.native && isEVM) {
                              adjustedTokenValue = BigInt.tryParse(
                                      widget.tx.evm?.value ?? "0") ??
                                  BigInt.zero;
                            }

                            final tx = _prepareTx(adjustedTokenValue);
                            HistoricalTransactionInfo? sendedTx;

                            if (_isLedgerWallet) {
                              sendedTx = await _signAndSendLedger(appState, tx);
                            } else {
                              sendedTx = await _signAndSend(appState, tx);
                            }

                            if (mounted && sendedTx != null) {
                              widget.onConfirm(sendedTx);
                            }
                          } catch (e) {
                            debugPrint("send tx err: $e");
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
            url: processTokenLogo(
              token: token,
              shortName: state.chain?.shortName ?? "",
              theme: theme.value,
            ),
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
      BaseTokenInfo token = widget.tx.metadata.tokenInfo ??
          BaseTokenInfo(
              value: '',
              symbol: widget.token.symbol,
              decimals: widget.token.decimals);

      final signer = appState.account ??
          (throw Exception(AppLocalizations.of(context)!
              .confirmTransactionContentNoActiveAccount));

      final amount = toDecimalsWei(widget.amount.toString(), token.decimals);
      final balance = BigInt.parse(
          widget.token.balances[appState.wallet!.selectedAccount] ?? '0');

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TransactionAmountDisplay(
              amount: amount,
              fee: _totalFee,
              token: widget.token,
              balance: balance,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            TokenTransferInfo(
              fromAddress: signer.addr,
              fromName: signer.name,
              toAddress: widget.to,
              textColor: textColor,
              secondaryColor: secondaryColor,
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!
          .confirmTransactionContentFailedLoadTransfer);
      return const SizedBox.shrink();
    }
  }
}
