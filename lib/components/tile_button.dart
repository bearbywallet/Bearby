import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/state/app_state.dart';

class TileButton extends StatefulWidget {
  final String? title;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final BorderSide? defaultBorderSide;
  final BorderRadius? borderRadius;
  final double? defaultSize;
  final bool disabled;
  final bool fillWidth;

  const TileButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.title,
    this.backgroundColor = const Color(0xFF2C2C2E),
    this.textColor = const Color(0xFF9D4BFF),
    this.defaultBorderSide,
    this.borderRadius,
    this.defaultSize,
    this.disabled = false,
    this.fillWidth = false,
  });

  @override
  State<TileButton> createState() => _TileButtonState();
}

class _TileButtonState extends State<TileButton>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(
      duration: const Duration(milliseconds: 120),
      scaleEnd: 0.95,
      opacityEnd: 0.85,
    );
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final scaleFactor = AdaptiveSize.getScaleFactor(context);
    final bool hasTitle =
        widget.title != null && widget.title!.trim().isNotEmpty;

    final double buttonScale = AdaptiveSize.getAdaptiveButtonScale(context);
    final double baseIconSize = hasTitle ? 34.0 : 20.0;
    final double iconSize = baseIconSize * buttonScale;
    final BorderRadius resolvedRadius =
        widget.borderRadius ?? BorderRadius.circular(18.0);

    double containerSize;
    if (widget.defaultSize != null) {
      containerSize = widget.defaultSize!;
    } else if (hasTitle) {
      final double estimatedFontSize =
          (theme.caption.fontSize ?? 14.0) * scaleFactor;
      final double estimatedLineHeightFactor = theme.caption.height ?? 1.3;
      final double actualTextHeight =
          estimatedFontSize * estimatedLineHeightFactor;
      final double padding = 12.0 * buttonScale;

      containerSize = padding +
          iconSize +
          6.0 * buttonScale +
          actualTextHeight +
          padding;
    } else {
      containerSize = 48.0 * buttonScale;
    }

    final double padding = 12.0 * buttonScale;
    Widget buttonContent;

    if (hasTitle) {
      buttonContent = Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Center(child: widget.icon),
            ),
            SizedBox(height: 6 * buttonScale),
            Flexible(
              child: Text(
                widget.title!,
                style: theme.caption.copyWith(
                  color: widget.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: AdaptiveSize.getAdaptiveFontSize(
                    context,
                    theme.caption.fontSize ?? 14.0,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      buttonContent = Center(
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: widget.icon,
        ),
      );
    }

    final Color borderColor = (isHovered && !widget.disabled)
        ? widget.textColor.withValues(alpha: 0.55)
        : (widget.defaultBorderSide?.color != null &&
                widget.defaultBorderSide!.color != Colors.transparent
            ? widget.defaultBorderSide!.color
            : theme.textPrimary.withValues(alpha: 0.08));

    return buildPressableWithOpacity(
      onTap: widget.onPressed,
      disabled: widget.disabled,
      enableHover: true,
      child: Opacity(
        opacity: widget.disabled ? 0.5 : 1.0,
        child: SizedBox(
          width: widget.fillWidth ? double.infinity : containerSize,
          height: containerSize,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: resolvedRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    widget.backgroundColor,
                    widget.textColor,
                    (isHovered && !widget.disabled) ? 0.14 : 0.05,
                  )!,
                  widget.backgroundColor,
                ],
              ),
              border: Border.all(
                color: borderColor,
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: (isHovered && !widget.disabled) ? 0.14 : 0.05,
                  ),
                  blurRadius: (isHovered && !widget.disabled) ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
