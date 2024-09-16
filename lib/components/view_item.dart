import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class WalletListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const WalletListItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: theme.primaryPurple, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: theme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

