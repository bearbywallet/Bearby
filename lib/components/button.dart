import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double borderRadius;
  final Color textColor;
  final Color backgroundColor;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool disabled;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderRadius = 30.0,
    required this.textColor,
    required this.backgroundColor,
    this.width = double.infinity,
    this.height = 56.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.disabled = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    return GestureDetector(
      onTap: widget.disabled ? null : widget.onPressed,
      onTapDown:
          widget.disabled ? null : (_) => setState(() => _isHovered = true),
      onTapUp:
          widget.disabled ? null : (_) => setState(() => _isHovered = false),
      onTapCancel:
          widget.disabled ? null : () => setState(() => _isHovered = false),
      child: Focus(
        canRequestFocus: !widget.disabled,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.disabled
                ? widget.backgroundColor.withValues(alpha: 0.5)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          transform: _isHovered
              ? Matrix4.diagonal3Values(0.9, 0.9, 1)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.text,
                style: theme.titleMedium.copyWith(
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
