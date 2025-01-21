import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showConfirmTransferModal({
  required BuildContext context,
  required FTokenInfo token,
  required String amount,
  required String fromAddress,
  required String toAddress,
  required VoidCallback onConfirm,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => _ConfirmTransferContent(
      token: token,
      amount: amount,
      fromAddress: fromAddress,
      toAddress: toAddress,
      onConfirm: onConfirm,
    ),
  );
}

class _ConfirmTransferContent extends StatelessWidget {
  final FTokenInfo token;
  final String amount;
  final String fromAddress;
  final String toAddress;
  final VoidCallback onConfirm;

  const _ConfirmTransferContent({
    required this.token,
    required this.amount,
    required this.fromAddress,
    required this.toAddress,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final estimatedGas = '0.001';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirm Transfer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildTransferDetails(theme),
          const SizedBox(height: 24),
          _buildTransferSummary(theme, estimatedGas),
          const SizedBox(height: 24),
          _buildConfirmButton(theme),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTransferDetails(AppTheme theme) {
    return Column(
      children: [
        Row(
          children: [
            // TokenIcon(token: token, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$amount ${token.symbol}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  Text(
                    formatFiatAmount(amount, 0),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildAddressRow('From', fromAddress, theme),
        const SizedBox(height: 12),
        _buildAddressRow('To', toAddress, theme),
      ],
    );
  }

  Widget _buildAddressRow(String label, String address, AppTheme theme) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 14,
              color: theme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTransferSummary(AppTheme theme, String estimatedGas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Network Fee', '$estimatedGas ZIL', theme),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Total Amount',
            '${(double.parse(amount) + double.parse(estimatedGas)).toStringAsFixed(8)} ZIL',
            theme,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, AppTheme theme,
      [bool isTotal = false]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: theme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(AppTheme theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Confirm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.background,
          ),
        ),
      ),
    );
  }
}

String formatFiatAmount(String amount, double price) {
  final value = double.parse(amount) * price;
  return '\$${value.toStringAsFixed(2)}';
}
