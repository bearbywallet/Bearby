import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class WalletListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback onTap;

  const WalletListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

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
                _buildIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style:
                            TextStyle(color: theme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (icon is IconData) {
      return Icon(icon as IconData);
    } else if (icon is Widget) {
      return icon;
    } else if (icon is String) {
      return Image.asset(
        icon,
        width: 24,
        height: 24,
      );
    }
    return Container();
  }
}
