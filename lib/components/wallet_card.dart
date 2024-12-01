import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/theme/theme_provider.dart';

class WalletCard extends StatelessWidget {
  final String name;
  final String address;
  final String balance;
  final VoidCallback onTap;
  final bool isSelected;
  final double? width;
  final double? height;
  final double? fontSize;
  final double avatarSize;

  const WalletCard({
    super.key,
    required this.name,
    required this.address,
    required this.balance,
    required this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
    this.fontSize,
    this.avatarSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: theme.primaryPurple,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryPurple.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Blockies(
                  seed: address,
                  color: getWalletColor(0),
                  bgColor: theme.primaryPurple,
                  spotColor: theme.background,
                  size: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: fontSize ?? 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: TextStyle(
                      color: theme.textPrimary.withOpacity(0.5),
                      fontSize: (fontSize ?? 16) - 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              balance,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: fontSize ?? 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
