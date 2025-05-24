import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class EnableCard extends StatelessWidget {
  final String title;
  final String name;
  final Widget? iconWidget;
  final bool isDefault;
  final bool isEnabled;
  final void Function(bool)? onToggle;

  const EnableCard({
    super.key,
    required this.title,
    required this.name,
    this.iconWidget,
    required this.isDefault,
    required this.isEnabled,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    const double iconSize = 32.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (iconWidget != null)
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: iconWidget,
              ),
            ),
          if (iconWidget != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.bodyText1.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: theme.bodyText2.copyWith(
                    color: theme.textSecondary,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: isDefault ? true : isEnabled,
            onChanged: isDefault ? null : onToggle,
            activeColor: isDefault ? theme.textSecondary : theme.primaryPurple,
          ),
        ],
      ),
    );
  }
}
