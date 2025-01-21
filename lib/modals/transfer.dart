import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/icon.dart';
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
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
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
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final gas = '0.00254329';
    final gasUsd = '0.01';
    final amountUsd = '5.09';

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
              'Transfer ${token.symbol}',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTransferDetails(appState, gas, gasUsd, amountUsd),
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
            state.chain!.chainId,
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
  ) {
    final theme = appState.currentTheme;
    final token = appState.wallet!.tokens.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow('Wallet', appState.account!.name, theme),
          const SizedBox(height: 16),
          _buildDetailRow('Recipient', shortenAddress(toAddress), theme),
          const SizedBox(height: 16),
          _buildAmountRow('Amount', amount, convertedAmount, theme),
          const SizedBox(height: 16),
          _buildAmountRow('Fee', '≈ $gas ${token.symbol}', gasUsd, theme),
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
      String label, String amount, String usd, AppTheme theme) {
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
              usd,
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
        onPressed: onConfirm,
      ),
    );
  }
}
