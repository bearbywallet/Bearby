import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

class NetworkOptionItem extends StatelessWidget {
  final AppTheme theme;
  final String name;
  final String chainId;
  final String currentNode;
  final VoidCallback onNodeTap;
  final bool isSelected;
  final String iconPath;

  const NetworkOptionItem({
    super.key,
    required this.theme,
    required this.name,
    required this.chainId,
    required this.currentNode,
    required this.onNodeTap,
    required this.isSelected,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? theme.primaryPurple : theme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? theme.primaryPurple : theme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Chain ID: $chainId',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: isSelected ? onNodeTap : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: isSelected
                  ? theme.background
                  : theme.background.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.primaryPurple
                      : theme.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              currentNode,
              style: TextStyle(
                color: isSelected
                    ? theme.primaryPurple
                    : theme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
