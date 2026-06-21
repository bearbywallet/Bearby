import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show pi, sin;

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/state/app_state.dart';

class SmartInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final Function(String)? onChanged;
  final Function()? onLeftIconTap;
  final Function()? onRightIconTap;
  final Function(String)? onSubmitted;
  final Function(bool)? onFocusChanged;
  final AppIcon? leftIcon;
  final AppIcon? rightIcon;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? height;
  final double? width;
  final double? fontSize;
  final EdgeInsets? padding;
  final EdgeInsets? iconPadding;
  final bool disabled;
  final bool autofocus;
  final TextInputType keyboardType;
  final Color? textColor;
  final Color? secondaryColor;
  final Color? backgroundColor;

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
    this.leftIcon,
    this.rightIcon,
    this.borderColor,
    this.focusedBorderColor,
    this.height = 48,
    this.width,
    this.fontSize = 16,
    this.padding,
    this.iconPadding,
    this.disabled = false,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.textColor,
    this.secondaryColor,
    this.backgroundColor,
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

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.disabled) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    }
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
    required AppIcon? icon,
    required Color color,
    Function()? onTap,
  }) {
    if (icon == null) return null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding:
            widget.iconPadding ?? const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppIconView(
            icon: icon,
            size: _iconSize * 0.7,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    final defaultFocusedBorderColor =
        widget.focusedBorderColor ?? theme.primaryPurple;

    final effectiveTextColor = widget.textColor ?? theme.textPrimary;
    final effectiveSecondaryColor =
        widget.secondaryColor ?? theme.textSecondary;

    final iconColor =
        _isFocused ? defaultFocusedBorderColor : effectiveSecondaryColor;

    Color getBorderColor() {
      if (widget.disabled) {
        return widget.borderColor ?? theme.modalBorder;
      }
      if (_isFocused) {
        return defaultFocusedBorderColor;
      }
      return widget.borderColor ?? theme.modalBorder;
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? theme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: getBorderColor(),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.leftIcon != null)
                      _buildIcon(
                            icon: widget.leftIcon,
                            color: iconColor,
                            onTap:
                                widget.disabled ? null : widget.onLeftIconTap,
                          ) ??
                          const SizedBox(),
                    Expanded(
                      child: Padding(
                        padding: widget.padding ??
                            EdgeInsets.symmetric(
                              horizontal: widget.leftIcon == null &&
                                      widget.rightIcon == null
                                  ? 16
                                  : 8,
                            ),
                        child: TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          obscureText: widget.obscureText,
                          onChanged: widget.onChanged,
                          enabled: !widget.disabled,
                          onFieldSubmitted: (value) {
                            if (!widget.disabled) {
                              widget.onSubmitted?.call(value);
                            }
                          },
                          style: theme.bodyText1.copyWith(
                            color: widget.disabled
                                ? effectiveTextColor.withValues(alpha: 0.5)
                                : effectiveTextColor,
                            fontSize: widget.fontSize,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.hint,
                            hintStyle: theme.bodyText1.copyWith(
                              color: widget.disabled
                                  ? effectiveSecondaryColor.withValues(
                                      alpha: 0.5)
                                  : effectiveSecondaryColor,
                              fontSize: widget.fontSize,
                            ),
                          ),
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: null,
                          keyboardType: widget.keyboardType,
                        ),
                      ),
                    ),
                    if (widget.rightIcon != null)
                      _buildIcon(
                            icon: widget.rightIcon,
                            color: iconColor,
                            onTap:
                                widget.disabled ? null : widget.onRightIconTap,
                          ) ??
                          const SizedBox(),
                  ],
                ),
              ),
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
