import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class SwitchSettingItem extends StatelessWidget {
  final String title;
  final String iconPath;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? backgroundColor;

  const SwitchSettingItem({
    super.key,
    required this.title,
    required this.iconPath,
    required this.description,
    required this.value,
    required this.onChanged,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  theme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.bodyText1.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: theme.primaryPurple,
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                description,
                style: theme.bodyText2.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    } else {
      return content;
    }
  }
}
