import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
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
  const _ConfirmTransactionContent({
    required this.tx,
    required this.amount,
    required this.to,
    required this.onConfirm,
  });

  final TransactionRequestInfo tx;
  final String to;
  final String amount;
  final VoidCallback onConfirm;

  @override
  State<_ConfirmTransactionContent> createState() =>
      _ConfirmTransactionContentState();
}

class _ConfirmTransactionContentState
    extends State<_ConfirmTransactionContent> {
  String _gasUsd = '0';
  String _amountUsd = '0';
  String _gasFee = '0';
  late TransactionRequestInfo _tx;

  @override
  void initState() {
    super.initState();
    _tx = widget.tx;
    _handleModalOpen();
  }

  Future<void> _handleModalOpen() async {
    final updatedTx = await caclGasFee(params: _tx);
    setState(() {
      _tx = updatedTx;
      _gasFee = calculateGasFee();
    });
  }

  void _updateTx(TransactionRequestInfo newTx) {
    setState(() {
      _tx = newTx;
    });
  }

  bool get isEVM => _tx.evm != null;

  String get fromAddress => isEVM ? _tx.evm!.from! : _tx.metadata.signer!;

  String get gasPrice => isEVM
      ? _tx.evm!.gasPrice?.toString() ?? _tx.evm!.maxFeePerGas.toString()
      : _tx.scilla!.gasPrice.toString();

  String get gasLimit =>
      isEVM ? _tx.evm!.gasLimit.toString() : _tx.scilla!.gasLimit.toString();

  String calculateGasFee() {
    if (isEVM) {
      final BigInt gasLimit = _tx.evm?.gasLimit ?? BigInt.from(21000);

      BigInt price;
      if (_tx.evm?.gasPrice != null) {
        price = _tx.evm!.gasPrice!;
      } else if (_tx.evm?.maxFeePerGas != null) {
        price = _tx.evm!.maxFeePerGas!;
      } else {
        price = BigInt.from(0);
      }

      return (price * gasLimit).toString();
    } else {
      if (_tx.scilla == null) {
        return "0";
      }
      return (_tx.scilla!.gasPrice * _tx.scilla!.gasLimit).toString();
    }
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
                color: theme.textSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildTokenLogo(appState),
            const SizedBox(height: 8),
            Text(
              _tx.metadata.title ?? 'Confirm Transaction',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_tx.metadata.info != null) ...[
              const SizedBox(height: 8),
              Text(
                _tx.metadata.info!,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildTransferDetails(
                appState, _gasFee, _gasUsd, _amountUsd, networkToken),
            const SizedBox(height: 24),
            _buildConfirmButton(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenLogo(AppState state) {
    final theme = state.currentTheme;
    final token = state.wallet!.tokens
        .firstWhere((t) => t.symbol == _tx.metadata.tokenInfo?.symbol);
    final chainId = _tx.evm?.chainId ?? BigInt.from(_tx.scilla?.chainId ?? 0);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryPurple.withOpacity(0.1),
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
    String gas,
    String gasUsd,
    String convertedAmount,
    String networkToken,
  ) {
    final theme = appState.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (_tx.metadata.signer != null)
            _buildDetailRow('From', shortenAddress(fromAddress), theme),
          const SizedBox(height: 16),
          _buildDetailRow('To', shortenAddress(widget.to), theme),
          const SizedBox(height: 16),
          _buildAmountRow('Amount', widget.amount, convertedAmount, theme),
          const SizedBox(height: 16),
          _buildDetailRow('Gas Limit', gasLimit, theme),
          const SizedBox(height: 16),
          _buildDetailRow('Gas Price', '$gasPrice Gwei', theme),
          const SizedBox(height: 16),
          _buildAmountRow('Network Fee', '$gas $networkToken', gasUsd, theme),
          if (!isEVM) ...[
            const SizedBox(height: 16),
            _buildDetailRow('Chain ID', _tx.scilla!.chainId.toString(), theme),
          ],
        ],
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
}
