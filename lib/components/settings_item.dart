import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class SettingsItem extends StatefulWidget {
  final String title;
  final String trailingSvgPath;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isGrouped;

  const SettingsItem({
    super.key,
    required this.title,
    required this.trailingSvgPath,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isGrouped = true,
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  bool _isPressed = false;

  ({double iconSize, double fontSize, double padding, double borderRadius})
      _getDynamicSizes(BuildContext context) {
    const double baseIconSize = 26.0;
    const double baseFontSize = 17.0;
    const double basePadding = 16.0;
    const double baseBorderRadius = 20.0;
    double sizeMultiplier = 1.0;

    return (
      iconSize: baseIconSize * sizeMultiplier,
      fontSize: baseFontSize * sizeMultiplier,
      padding: basePadding * sizeMultiplier,
      borderRadius: baseBorderRadius * sizeMultiplier,
    );
  }

  BorderRadius? _getBorderRadius(double borderRadius) {
    if (widget.isGrouped) {
      if (widget.isFirst && widget.isLast) {
        return BorderRadius.circular(borderRadius);
      } else if (widget.isFirst) {
        return BorderRadius.vertical(top: Radius.circular(borderRadius));
      } else if (widget.isLast) {
        return BorderRadius.vertical(bottom: Radius.circular(borderRadius));
      }
    } else {
      return BorderRadius.circular(borderRadius);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final sizes = _getDynamicSizes(context);
    final borderRadius = _getBorderRadius(sizes.borderRadius);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: sizes.padding,
          vertical: sizes.padding * 0.8,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? theme.background.withValues(alpha: 1.0)
              : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: theme.bodyText1.copyWith(
                  color: theme.textPrimary,
                  fontSize: sizes.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SvgPicture.asset(
              widget.trailingSvgPath,
              colorFilter: ColorFilter.mode(
                theme.textSecondary,
                BlendMode.srcIn,
              ),
              width: sizes.iconSize,
              height: sizes.iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
