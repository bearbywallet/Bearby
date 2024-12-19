import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class WalletSelectionCard extends StatelessWidget {
  final String walletName;
  final int transferCount;
  final VoidCallback onTap;
  final bool isSelected;

  const WalletSelectionCard({
    super.key,
    required this.walletName,
    required this.transferCount,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryPurple,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryPurple,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    walletName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$transferCount previous transfers',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
