import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:bearby/state/app_state.dart';

class GlassSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String) onSubmitted;
  final Function(String)? onChanged;
  final Function(bool)? onFocusChanged;
  final Function()? onRightIconTap;
  final String leftIconPath;
  final String? rightIconPath;
  final TextInputType keyboardType;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.onChanged,
    this.onFocusChanged,
    this.onRightIconTap,
    this.leftIconPath = 'assets/icons/search.svg',
    this.rightIconPath,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<GlassSearchBar> createState() => GlassSearchBarState();
}

class GlassSearchBarState extends State<GlassSearchBar>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: const _GlassSearchBarShakeCurve()))
        .animate(_shakeController);

    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void shake() {
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusController.dispose();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _focusAnimation,
        builder: (context, _) {
          final t = _focusAnimation.value;

          final borderColor = Color.lerp(
            theme.modalBorder,
            theme.primaryPurple.withValues(alpha: 0.55),
            t,
          )!;

          final iconColor = Color.lerp(
            theme.textSecondary,
            theme.primaryPurple,
            t,
          )!;

          return SizedBox(
            height: 48,
            child: Stack(
              children: [
                // Layer 0 — Blur backdrop
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),

                // Layer 1 — Glass body with animated border + shadow
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.cardBackground.withValues(alpha: 0.18),
                          theme.cardBackground.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),

                // Layer 2 — Top highlight strip (glass light refraction)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Layer 3 — Content row
                Positioned.fill(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SvgPicture.asset(
                          widget.leftIconPath,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            iconColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          onChanged: widget.onChanged,
                          onFieldSubmitted: widget.onSubmitted,
                          style: theme.bodyText1.copyWith(
                            color: theme.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.hint,
                            hintStyle: theme.bodyText1.copyWith(
                              color: theme.textSecondary,
                              fontSize: 15,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: null,
                          keyboardType: widget.keyboardType,
                        ),
                      ),
                      if (widget.rightIconPath != null)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onRightIconTap,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: SvgPicture.asset(
                              widget.rightIconPath!,
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                iconColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlassSearchBarShakeCurve extends Curve {
  const _GlassSearchBarShakeCurve();

  @override
  double transform(double t) => sin(t * pi * 5) * (1 - t);
}
