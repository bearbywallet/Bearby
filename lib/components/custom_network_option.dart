import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

class CustomNetworkOption extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final String customUrl;
  final VoidCallback onConfigureTap;

  const CustomNetworkOption({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.customUrl,
    required this.onConfigureTap,
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
                'assets/icons/documents.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? theme.primaryPurple : theme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Network',
                    style: TextStyle(
                      color:
                          isSelected ? theme.primaryPurple : theme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure your own network settings',
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onConfigureTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: isSelected
                  ? theme.background
                  : theme.background.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.primaryPurple
                      : theme.textSecondary.withOpacity(0.5),
                ),
              ),
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              customUrl.isEmpty ? 'Configure Network' : customUrl,
              style: TextStyle(
                color: isSelected
                    ? theme.primaryPurple
                    : theme.textPrimary.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
