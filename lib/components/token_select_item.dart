import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/state/app_state.dart';

class TokenSelectItem extends StatelessWidget {
  final String symbol;
  final String name;
  final String balance;
  final String iconUrl;
  final VoidCallback onTap;
  final double iconSize;

  const TokenSelectItem({
    super.key,
    required this.symbol,
    required this.name,
    required this.balance,
    required this.iconUrl,
    required this.onTap,
    this.iconSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(iconSize / 2),
                child: SvgPicture.network(
                  iconUrl,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(iconSize / 2),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: iconSize / 2,
                        height: iconSize / 2,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$20',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
