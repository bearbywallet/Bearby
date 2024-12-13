import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' show pi, sin;

import 'package:zilpay/state/app_state.dart';

class SmartInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final Function(String)? onChanged;
  final Function()? onLeftIconTap;
  final Function()? onRightIconTap;
  final Function()? onSubmitted;
  final Function(bool)? onFocusChanged;
  final String? leftIconPath;
  final String? rightIconPath;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? height;
  final double? width;
  final double? fontSize;
  final EdgeInsets? padding;
  final EdgeInsets? iconPadding;
  final bool disabled;

  const SmartInput({
    super.key,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.onChanged,
    this.onLeftIconTap,
    this.onRightIconTap,
    this.onSubmitted,
    this.onFocusChanged,
    this.leftIconPath,
    this.rightIconPath,
    this.borderColor,
    this.focusedBorderColor,
    this.height = 48,
    this.width,
    this.fontSize = 16,
    this.padding,
    this.iconPadding,
    this.disabled = false,
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

    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;

    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (widget.onFocusChanged != null) {
      widget.onFocusChanged!(_focusNode.hasFocus);
    }
  }

  void shake() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _iconSize {
    final containerHeight = widget.height ?? 48;
    return containerHeight * 0.416;
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
          colorFilter: ColorFilter.mode(
            color,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

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
              color: widget.disabled
                  ? theme.cardBackground.withOpacity(0.5)
                  : theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.disabled
                    ? defaultBorderColor.withOpacity(0.3)
                    : _isFocused
                        ? (widget.focusedBorderColor ??
                            defaultFocusedBorderColor)
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
                        onTap: widget.disabled ? null : widget.onLeftIconTap,
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
                      enabled: !widget.disabled,
                      onFieldSubmitted: (_) {
                        if (!widget.disabled) {
                          widget.onSubmitted?.call();
                        }
                      },
                      style: TextStyle(
                        color: widget.disabled
                            ? theme.textPrimary.withOpacity(0.5)
                            : theme.textPrimary,
                        fontSize: widget.fontSize,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: widget.disabled
                              ? theme.textSecondary.withOpacity(0.5)
                              : theme.textSecondary,
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
                        onTap: widget.disabled ? null : widget.onRightIconTap,
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
