import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zilpay/theme/app_theme.dart';

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
            child: Text(
              widget.text,
              style: Theme.of(context).extension<AppTheme>()!.subtitle1.copyWith(
                    color: widget.disabled
                        ? widget.textColor.withAlpha(128) // Using withAlpha for 0.5 opacity
                        : widget.textColor,
                    fontWeight: FontWeight.bold, // subtitle1 is w500, explicit bold needed
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
