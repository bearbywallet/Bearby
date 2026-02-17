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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: sizes.padding,
          vertical: sizes.padding * 0.8,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: theme.subtitle2.copyWith(
                  color: theme.textPrimary,
                  fontSize: sizes.fontSize,
                  shadows: [
                    Shadow(
                      color: theme.background.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                widget.trailingSvgPath,
                colorFilter: ColorFilter.mode(
                  theme.textSecondary,
                  BlendMode.srcIn,
                ),
                width: sizes.iconSize * 0.7,
                height: sizes.iconSize * 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
