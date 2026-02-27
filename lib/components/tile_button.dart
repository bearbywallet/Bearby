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
  final bool disabled;

  const TileButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.title,
    this.backgroundColor = const Color(0xFF2C2C2E),
    this.textColor = const Color(0xFF9D4BFF),
    this.defaultBorderSide,
    this.disabled = false,
  });

  @override
  State<TileButton> createState() => _TileButtonState();
}

class _TileButtonState extends State<TileButton>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(scaleEnd: 0.90, opacityEnd: 0.7);
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  BorderSide _getBorderSide() {
    final base =
        widget.defaultBorderSide ?? const BorderSide(color: Colors.transparent);
    if (isHovered && !widget.disabled) {
      return base.copyWith(
        color: widget.textColor,
        width: 2.0,
      );
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final scaleFactor = AdaptiveSize.getScaleFactor(context);

    final bool hasTitle = widget.title != null && widget.title!.isNotEmpty;

    final double buttonScale = AdaptiveSize.getAdaptiveButtonScale(context);
    final double baseIconSize = hasTitle ? 34.0 : 20.0;
    final double iconSize = baseIconSize * buttonScale;
    final double borderRadius = 16.0 * buttonScale;

    double containerSize;

    if (hasTitle) {
      final double estimatedFontSize =
          (theme.caption.fontSize ?? 14.0) * scaleFactor;
      final double estimatedLineHeightFactor = theme.caption.height ?? 1.3;
      final double actualTextHeightForTwoLines =
          estimatedFontSize * 2 * estimatedLineHeightFactor;
      final double padding = 12.0 * buttonScale;

      containerSize = padding +
          iconSize +
          4.0 * buttonScale +
          actualTextHeightForTwoLines +
          padding;
    } else {
      containerSize = 48.0 * buttonScale;
    }

    Widget buttonContent;
    final double padding = 12.0 * buttonScale;

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
            SizedBox(height: 4 * buttonScale),
            Text(
              widget.title!,
              style: theme.caption.copyWith(
                color: widget.textColor,
                fontSize: AdaptiveSize.getAdaptiveFontSize(
                  context,
                  theme.caption.fontSize ?? 14.0,
                ),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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

    return buildPressableWithOpacity(
      onTap: widget.onPressed,
      disabled: widget.disabled,
      enableHover: true,
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.fromBorderSide(_getBorderSide()),
        ),
        child: buttonContent,
      ),
    );
  }
}
