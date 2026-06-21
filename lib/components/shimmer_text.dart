import 'package:flutter/material.dart';

/// Renders [text] with a bright highlight band sweeping horizontally across the
/// glyphs — a lightweight loading state for a single value.
///
/// Only build this when actually loading: it runs an [AnimationController] for
/// the lifetime of the widget. When idle, render a plain [Text] instead.
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Muted color the glyphs rest at.
  final Color baseColor;

  /// Bright color of the sweeping band.
  final Color highlightColor;

  final TextAlign? textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    required this.baseColor,
    required this.highlightColor,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = widget.baseColor;
    final Color highlight = widget.highlightColor;

    final Text child = Text(
      widget.text,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      style: widget.style.copyWith(color: Colors.white),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? innerChild) {
        final double t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.1, 0.5, 0.9],
              begin: Alignment(-3.0 + 4.0 * t, 0),
              end: Alignment(-1.0 + 4.0 * t, 0),
            ).createShader(bounds);
          },
          child: innerChild,
        );
      },
      child: child,
    );
  }
}
