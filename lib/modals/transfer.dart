import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gas_eip1559.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/components/token_transfer_amount.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showConfirmTransactionModal({
  required BuildContext context,
  required TransactionRequestInfo tx,
  required String to,
  required String amount,
  required int tokenIndex,
  required VoidCallback onConfirm,
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
      onConfirm: onConfirm,
    ),
  );
}

class _ConfirmTransactionContent extends StatefulWidget {
  final TransactionRequestInfo tx;
  final String to;
  final int tokenIndex;
  final String amount;
  final VoidCallback onConfirm;

  const _ConfirmTransactionContent({
    required this.tx,
    required this.amount,
    required this.to,
    required this.tokenIndex,
    required this.onConfirm,
  });

  @override
  State<_ConfirmTransactionContent> createState() =>
      _ConfirmTransactionContentState();
}

class _ConfirmTransactionContentState
    extends State<_ConfirmTransactionContent> {
  GasInfo _gasInfo = GasInfo(
    gasPrice: BigInt.zero,
    maxPriorityFee: BigInt.zero,
    feeHistory: GasFeeHistoryInfo(
      maxFee: BigInt.zero,
      priorityFee: BigInt.zero,
      baseFee: BigInt.zero,
    ),
    txEstimateGas: BigInt.zero,
    blobBaseFee: BigInt.zero,
  );
  bool loading = false;

  bool get isEVM => widget.tx.evm != null;

  @override
  void initState() {
    super.initState();
    _handleModalOpen();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
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
                color: theme.textSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildTokenLogo(appState),
            const SizedBox(height: 4),
            _buildTransferDetails(
              appState,
            ),
            if (isEVM) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GasEIP1559(
                  gasInfo: _gasInfo,
                  disabled: _gasInfo.gasPrice == BigInt.zero || loading,
                  onChange: (BigInt maxPriorityFee) {
                    print(maxPriorityFee);
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildConfirmButton(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SwipeButton(
        text: "Confirm",
        onSwipeComplete: () async {
          setState(() {
            loading = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            loading = false;
          });
        },
      ),
    );
  }

  Widget _buildTokenLogo(AppState state) {
    const double imageSize = 64;
    final theme = state.currentTheme;
    final token = state.wallet!.tokens
        .firstWhere((t) => t.symbol == widget.tx.metadata.tokenInfo?.symbol);
    final chainId =
        widget.tx.evm?.chainId ?? BigInt.from(widget.tx.scilla?.chainId ?? 0);

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: viewTokenIcon(
            token,
            chainId,
            theme.value,
          ),
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTransferDetails(
    AppState appState,
  ) {
    final token = appState.wallet!.tokens[widget.tokenIndex];
    final signer = appState.account;

    return Container(
      padding: const EdgeInsets.all(16),
      child: TokenTransferAmount(
        fromAddress: signer!.addr,
        fromName: signer.name,
        toAddress: widget.to,
        amount: widget.amount,
        symbol: token.symbol,
      ),
    );
  }

  Future<void> _handleModalOpen() async {
    final gas = await caclGasFee(params: widget.tx);
    setState(() => _gasInfo = gas);
  }
}
