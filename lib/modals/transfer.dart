import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/gas_eip1559.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/addr.dart';
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
      amount: amount,
      to: to,
      onConfirm: onConfirm,
    ),
  );
}

class _ConfirmTransactionContent extends StatefulWidget {
  final TransactionRequestInfo tx;
  final String to;
  final String amount;
  final VoidCallback onConfirm;

  const _ConfirmTransactionContent({
    required this.tx,
    required this.amount,
    required this.to,
    required this.onConfirm,
  });

  @override
  State<_ConfirmTransactionContent> createState() =>
      _ConfirmTransactionContentState();
}

class _ConfirmTransactionContentState
    extends State<_ConfirmTransactionContent> {
  final String _amountUsd = '0';
  GasInfo? _gasInfo;
  GasFeeOption _selectedGasType = GasFeeOption.market;

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
    final networkToken = isEVM ? 'ETH' : 'ZIL';

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
            const SizedBox(height: 8),
            Text(
              widget.tx.metadata.title ?? 'Confirm Transaction',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.tx.metadata.info != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.tx.metadata.info!,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildTransferDetails(appState, _amountUsd, networkToken),
            if (_gasInfo != null && isEVM) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GasEIP1559(
                  gasInfo: _gasInfo!,
                  selected: _selectedGasType,
                  onSelect: (type) => setState(() => _selectedGasType = type),
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

  Widget _buildAmountRow(
    String label,
    String amount,
    String usd,
    AppTheme theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 16,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\$$usd',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmButton(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomButton(
        text: "Confirm",
        onPressed: widget.onConfirm,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenLogo(AppState state) {
    final theme = state.currentTheme;
    final token = state.wallet!.tokens
        .firstWhere((t) => t.symbol == widget.tx.metadata.tokenInfo?.symbol);
    final chainId =
        widget.tx.evm?.chainId ?? BigInt.from(widget.tx.scilla?.chainId ?? 0);

    return Container(
      width: 64,
      height: 64,
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
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTransferDetails(
    AppState appState,
    String convertedAmount,
    String networkToken,
  ) {
    final theme = appState.currentTheme;
    final signer = appState.account;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (widget.tx.metadata.signer != null)
            _buildDetailRow('From', shortenAddress(signer?.addr ?? ""), theme),
          const SizedBox(height: 16),
          _buildDetailRow('To', shortenAddress(widget.to), theme),
          const SizedBox(height: 16),
          _buildAmountRow('Amount', widget.amount, convertedAmount, theme),
        ],
      ),
    );
  }

  Future<void> _handleModalOpen() async {
    if (isEVM) {
      final gas = await caclGasFee(params: widget.tx);
      setState(() => _gasInfo = gas);
    }
  }
}
