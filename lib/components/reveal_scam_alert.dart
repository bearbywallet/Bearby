import 'package:flutter/material.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/theme/app_theme.dart';

/// Compact one-line warning used on secret-reveal screens.
class RevealScamAlert extends StatelessWidget {
  final AppTheme theme;
  final String message;

  const RevealScamAlert({
    super.key,
    required this.theme,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          AppIconView(
            icon: AppIcon.warning,
            size: 20,
            color: theme.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.bodySmall.copyWith(color: theme.danger),
            ),
          ),
        ],
      ),
    );
  }
}
