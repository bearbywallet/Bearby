import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/theme/theme_provider.dart';

class LedgerItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final String id;

  const LedgerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryPurple, width: 2),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                id,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
