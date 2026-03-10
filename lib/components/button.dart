import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double borderRadius;
  final Color textColor;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool disabled;
  final bool glassEffect;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderRadius = 30,
    required this.textColor,
    required this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.width = double.infinity,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.disabled = false,
    this.glassEffect = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return GestureDetector(
      onTap: widget.disabled ? null : widget.onPressed,
      onTapDown:
          widget.disabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp:
          widget.disabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel:
          widget.disabled ? null : () => setState(() => _isPressed = false),
      child: Focus(
        canRequestFocus: !widget.disabled,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.disabled
                ? widget.backgroundColor.withValues(alpha: 0.4)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.borderColor != null
                ? Border.all(
                    color: widget.disabled
                        ? widget.borderColor!.withValues(alpha: 0.4)
                        : widget.borderColor!,
                    width: widget.borderWidth,
                  )
                : null,
            boxShadow: _isPressed || widget.borderColor != null
                ? null
                : [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          transform: _isPressed
              ? Matrix4.diagonal3Values(0.98, 0.98, 1)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.text,
                style: theme.labelLarge.copyWith(
                  color: widget.disabled
                      ? widget.textColor.withAlpha(128)
                      : widget.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
