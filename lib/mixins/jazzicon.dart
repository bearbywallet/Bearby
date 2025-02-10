import 'dart:math';
import 'package:flutter/widgets.dart';

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

class Jazzicon extends StatefulWidget {
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
  State<Jazzicon> createState() => _JazziconState();
}

class _JazziconState extends State<Jazzicon> {
  late final JazziconPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = JazziconPainter(
      seed: widget.seed,
      shapeCount: widget.shapeCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.diameter, widget.diameter),
        painter: _painter,
      ),
    );
  }
}

class JazziconPainter extends CustomPainter {
  final String seed;
  final int shapeCount;
  late final Random _random;
  late final List<Color> _colors;
  late final List<_ShapeConfig> _shapes;

  JazziconPainter({
    required this.seed,
    required this.shapeCount,
  }) {
    _random = Random(_generateSeedFromString(seed));
    _colors = _hueShift(List<Color>.from(JazzColors.colors));
    _shapes = _generateShapes();
  }

  int _generateSeedFromString(String str) {
    return str.codeUnits.fold(0, (prev, curr) => prev + curr);
  }

  List<_ShapeConfig> _generateShapes() {
    final shapes = <_ShapeConfig>[];
    final List<Color> remainingColors = List<Color>.from(_colors);

    // Background color
    final backgroundColor = _genColor(remainingColors);
    shapes.add(_ShapeConfig(
      color: backgroundColor,
      transform: Matrix4.identity(),
    ));

    // Generate other shapes
    for (var i = 0; i < shapeCount - 1; i++) {
      final shapeConfig = _genShapeConfig(i, shapeCount - 1, remainingColors);
      shapes.add(shapeConfig);
    }

    return shapes;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in _shapes) {
      canvas.save();
      canvas.transform(shape.transform.storage);

      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(rect, Paint()..color = shape.color);

      canvas.restore();
    }
  }

  _ShapeConfig _genShapeConfig(int i, int total, List<Color> remainingColors) {
    final center = Offset.zero;
    final firstRot = _random.nextDouble();
    final angle = 2 * pi * firstRot;
    final velocity = (_random.nextDouble() + i) / total;

    final tx = cos(angle) * velocity;
    final ty = sin(angle) * velocity;
    final secondRot = _random.nextDouble();
    final rot = (firstRot * 360) + secondRot * 180;

    final transform = Matrix4.identity()
      ..translate(tx, ty)
      ..translate(center.dx, center.dy)
      ..rotateZ(rot * pi / 180)
      ..translate(-center.dx, -center.dy);

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
