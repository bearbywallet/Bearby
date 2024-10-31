import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/theme_provider.dart';
import 'dart:math' show pi, sin;

class SmartInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final Function(String)? onChanged;
  final Function()? onLeftIconTap;
  final Function()? onRightIconTap;
  final Function()? onSubmitted;
  final String? leftIconPath;
  final String? rightIconPath;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? height;
  final double? width;
  final double? fontSize;
  final EdgeInsets? padding;
  final EdgeInsets? iconPadding;

  const SmartInput({
    super.key,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.onChanged,
    this.onLeftIconTap,
    this.onRightIconTap,
    this.onSubmitted,
    this.leftIconPath,
    this.rightIconPath,
    this.borderColor,
    this.focusedBorderColor,
    this.height = 48,
    this.width,
    this.fontSize = 16,
    this.padding,
    this.iconPadding,
  });

  @override
  State<SmartInput> createState() => SmartInputState();
}

class SmartInputState extends State<SmartInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: const InputShakeCurve()))
        .animate(_shakeController);

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  void shake() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _iconSize {
    final containerHeight = widget.height ?? 48;
    return containerHeight * 0.416; // ~20px when height is 48
  }

  Widget? _buildIcon({
    required String? iconPath,
    required Color color,
    Function()? onTap,
  }) {
    if (iconPath == null) return null;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding:
            widget.iconPadding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: SvgPicture.asset(
          iconPath,
          width: _iconSize,
          height: _iconSize,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    final defaultBorderColor = theme.textSecondary.withOpacity(0.3);
    final defaultFocusedBorderColor = theme.primaryPurple;

    final iconColor = _isFocused
        ? (widget.focusedBorderColor ?? defaultFocusedBorderColor)
        : theme.textSecondary;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? (widget.focusedBorderColor ?? defaultFocusedBorderColor)
                    : (widget.borderColor ?? defaultBorderColor),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                if (widget.leftIconPath != null)
                  _buildIcon(
                        iconPath: widget.leftIconPath,
                        color: iconColor,
                        onTap: widget.onLeftIconTap,
                      ) ??
                      const SizedBox(),
                Expanded(
                  child: Padding(
                    padding: widget.padding ??
                        EdgeInsets.symmetric(
                          horizontal: widget.leftIconPath == null &&
                                  widget.rightIconPath == null
                              ? 16
                              : 8,
                        ),
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      onChanged: widget.onChanged,
                      onFieldSubmitted: (_) {
                        shake();
                        widget.onSubmitted?.call();
                      },
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: widget.fontSize,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: theme.textSecondary,
                          fontSize: widget.fontSize,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.rightIconPath != null)
                  _buildIcon(
                        iconPath: widget.rightIconPath,
                        color: iconColor,
                        onTap: widget.onRightIconTap,
                      ) ??
                      const SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class InputShakeCurve extends Curve {
  const InputShakeCurve();

  @override
  double transform(double t) {
    return sin(t * pi * 5) * (1 - t);
  }
}
