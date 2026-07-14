import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/state/app_state.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback onBackPressed;
  final VoidCallback? onActionPressed;
  final Widget? actionIcon;
  final Widget? actionWidget;

  const CustomAppBar({
    super.key,
    required this.onBackPressed,
    this.title,
    this.onActionPressed,
    this.actionIcon,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final String? title = this.title;
    final Widget? actionWidget = this.actionWidget;
    final Widget? actionIcon = this.actionIcon;
    final VoidCallback? onActionPressed = this.onActionPressed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: AppIconView(
                icon: AppIcon.arrowLeft,
                size: 24,
                color: theme.textPrimary,
              ),
              onPressed: onBackPressed,
            ),
            if (title != null)
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.headline2.copyWith(
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (actionWidget != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: actionWidget,
              )
            else if (actionIcon != null && onActionPressed != null)
              IconButton(
                icon: actionIcon,
                onPressed: onActionPressed,
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
