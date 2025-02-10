import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zilpay/theme/app_theme.dart';

class Jazzicon extends StatefulWidget {
  final double diameter;
  final String seed;
  final int shapeCount;
  final AppTheme theme;

  const Jazzicon({
    super.key,
    required this.diameter,
    required this.seed,
    required this.theme,
    this.shapeCount = 4,
  });

  @override
  State<Jazzicon> createState() => _JazziconState();
}

class _JazziconState extends State<Jazzicon> {
  late final JazziconPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = JazziconPainter(
      seed: widget.seed,
      diameter: widget.diameter,
      theme: widget.theme,
      shapeCount: widget.shapeCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(widget.diameter, widget.diameter),
          painter: _painter,
        ),
      ),
    );
  }
}

class JazziconPainter extends CustomPainter {
  final String seed;
  final double diameter;
  final int shapeCount;
  late final Random _random;
  final AppTheme theme;
  late final List<Color> _colors;
  late final List<_ShapeConfig> _shapes;

  JazziconPainter({
    required this.seed,
    required this.diameter,
    required this.shapeCount,
    required this.theme,
  }) {
    if (seed.isEmpty) {
      throw ArgumentError('Seed cannot be empty');
    }

    _random = Random(_generateSeedFromString(seed));

    List<Color> colors = [
      theme.primaryPurple,
      theme.secondaryPurple,
      theme.background,
      theme.cardBackground,
      theme.textPrimary,
      theme.textSecondary,
      theme.buttonBackground,
      theme.success,
      theme.danger,
      theme.warning
    ];

    _colors = _hueShift(List<Color>.from(colors));
    _shapes = _generateShapes();
  }

  int _generateSeedFromString(String str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      var chr = str.codeUnitAt(i);
      hash = ((hash << 5) - hash) + chr;
      hash |= 0;
    }
    return hash.abs();
  }

  List<_ShapeConfig> _generateShapes() {
    final shapes = <_ShapeConfig>[];
    final List<Color> remainingColors = List<Color>.from(_colors);

    final backgroundColor = _genColor(remainingColors);
    shapes.add(_ShapeConfig(
      color: backgroundColor,
      transform: Matrix4.identity(),
    ));

    for (var i = 0; i < shapeCount - 1; i++) {
      final shapeConfig = _genShape(i, shapeCount - 1, remainingColors);
      shapes.add(shapeConfig);
    }

    return shapes;
  }

  _ShapeConfig _genShape(int i, int total, List<Color> remainingColors) {
    final center = diameter / 2;

    final firstRot = _random.nextDouble();
    final angle = 2 * pi * firstRot;
    final velocity =
        (diameter / total * _random.nextDouble()) + (i * diameter / total);

    final tx = cos(angle) * velocity;
    final ty = sin(angle) * velocity;

    final secondRot = _random.nextDouble();
    final rot = (firstRot * 360) + secondRot * 180;

    final transform = Matrix4.identity()
      ..translate(tx, ty)
      ..translate(center, center)
      ..rotateZ(rot * pi / 180)
      ..translate(-center, -center);

    return _ShapeConfig(
      color: _genColor(remainingColors),
      transform: transform,
    );
  }

  Color _genColor(List<Color> remainingColors) {
    if (remainingColors.isEmpty) return const Color(0xFF000000);
    final idx = (_random.nextDouble() * remainingColors.length).floor();
    return remainingColors.removeAt(idx);
  }

  List<Color> _hueShift(List<Color> colors) {
    const wobble = 30;
    final amount = (_random.nextDouble() * 30) - (wobble / 2);
    return colors.map((color) => _colorRotate(color, amount)).toList();
  }

  Color _colorRotate(Color color, double degrees) {
    final hsl = HSLColor.fromColor(color);
    var hue = hsl.hue;
    hue = (hue + degrees) % 360;
    hue = hue < 0 ? 360 + hue : hue;
    return hsl.withHue(hue).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in _shapes) {
      canvas.save();
      canvas.transform(shape.transform.storage);

      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(16.0),
      );

      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = shape.color;

      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(JazziconPainter oldDelegate) =>
      seed != oldDelegate.seed || shapeCount != oldDelegate.shapeCount;
}

class _ShapeConfig {
  final Color color;
  final Matrix4 transform;

  const _ShapeConfig({
    required this.color,
    required this.transform,
  });
}
