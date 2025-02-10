import 'dart:math';
import 'package:flutter/material.dart';

class JazzColors {
  static const List<Color> colors = [
    Color(0xFF01888C), // teal
    Color(0xFFFC7500), // bright orange
    Color(0xFF034F5D), // dark teal
    Color(0xFFF73F01), // orangered
    Color(0xFFFC1960), // magenta
    Color(0xFFC7144C), // raspberry
    Color(0xFFF3C100), // goldenrod
    Color(0xFF1598F2), // lightning blue
    Color(0xFF2465E1), // sail blue
    Color(0xFFF19E02), // gold
  ];
}

class Jazzicon extends StatelessWidget {
  final double diameter;
  final String seed;
  final int shapeCount;

  const Jazzicon({
    super.key,
    required this.diameter,
    required this.seed,
    this.shapeCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(diameter, diameter),
      painter: JazziconPainter(
        seed: seed,
        shapeCount: shapeCount,
      ),
    );
  }
}

class JazziconPainter extends CustomPainter {
  final String seed;
  final int shapeCount;
  late Random _random;
  late List<Color> _remainingColors;

  JazziconPainter({
    required this.seed,
    required this.shapeCount,
  }) {
    // Initialize random with seed
    _random = Random(_generateSeedFromString(seed));
    _remainingColors = List.from(JazzColors.colors);
    _remainingColors = _hueShift(_remainingColors);
  }

  int _generateSeedFromString(String str) {
    return str.codeUnits.fold(0, (prev, curr) => prev + curr);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final background = _genColor();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = background,
    );

    // Generate shapes
    for (var i = 0; i < shapeCount - 1; i++) {
      _genShape(canvas, size, i, shapeCount - 1);
    }
  }

  void _genShape(Canvas canvas, Size size, int i, int total) {
    final center = Offset(size.width / 2, size.height / 2);

    final firstRot = _random.nextDouble();
    final angle = 2 * pi * firstRot;
    final velocity =
        (size.width / total * _random.nextDouble()) + (i * size.width / total);

    final tx = cos(angle) * velocity;
    final ty = sin(angle) * velocity;

    final secondRot = _random.nextDouble();
    final rot = (firstRot * 360) + secondRot * 180;

    canvas.save();
    canvas.translate(tx, ty);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot * pi / 180);
    canvas.translate(-center.dx, -center.dy);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()..color = _genColor(),
    );

    canvas.restore();
  }

  Color _genColor() {
    final idx = (_random.nextDouble() * _remainingColors.length).floor();
    return _remainingColors.removeAt(idx);
  }

  List<Color> _hueShift(List<Color> colors) {
    final wobble = 30;
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
