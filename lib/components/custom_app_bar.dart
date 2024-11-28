import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback onBackPressed;
  final VoidCallback? onActionPressed;
  final String? actionIconPath;
  final String? actionText;

  const CustomAppBar({
    super.key,
    this.title,
    required this.onBackPressed,
    this.onActionPressed,
    this.actionIconPath,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/back.svg',
                width: 24,
                height: 24,
                color: theme.textPrimary,
              ),
              onPressed: onBackPressed,
            ),
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (actionText != null && onActionPressed != null)
              TextButton(
                onPressed: onActionPressed,
                child: Text(
                  actionText!,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (actionIconPath != null && onActionPressed != null)
              IconButton(
                icon: SvgPicture.asset(
                  actionIconPath!,
                  width: 30,
                  height: 30,
                  color: theme.textPrimary,
                ),
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
