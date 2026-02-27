import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

enum GlassMessageType { error, warning, success, info }

class GlassMessage extends StatelessWidget {
  final String message;
  final GlassMessageType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onDismiss;

  const GlassMessage({
    super.key,
    required this.message,
    this.type = GlassMessageType.error,
    this.padding,
    this.margin,
    this.onDismiss,
  });

  Color _getBackgroundColor(AppTheme theme) {
    switch (type) {
      case GlassMessageType.error:
        return theme.danger.withValues(alpha: 0.15);
      case GlassMessageType.warning:
        return theme.warning.withValues(alpha: 0.15);
      case GlassMessageType.success:
        return theme.success.withValues(alpha: 0.15);
      case GlassMessageType.info:
        return theme.primaryPurple.withValues(alpha: 0.15);
    }
  }

  Color _getBorderColor(AppTheme theme) {
    switch (type) {
      case GlassMessageType.error:
        return theme.danger.withValues(alpha: 0.25);
      case GlassMessageType.warning:
        return theme.warning.withValues(alpha: 0.25);
      case GlassMessageType.success:
        return theme.success.withValues(alpha: 0.25);
      case GlassMessageType.info:
        return theme.primaryPurple.withValues(alpha: 0.25);
    }
  }

  Color _getTextColor(AppTheme theme) {
    switch (type) {
      case GlassMessageType.error:
        return theme.danger;
      case GlassMessageType.warning:
        return theme.warning;
      case GlassMessageType.success:
        return theme.success;
      case GlassMessageType.info:
        return theme.primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(theme),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(theme),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: theme.bodyText2.copyWith(
                      color: _getTextColor(theme),
                    ),
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: SvgPicture.asset(
                      'assets/icons/close.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        _getTextColor(theme).withValues(alpha: 0.7),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
