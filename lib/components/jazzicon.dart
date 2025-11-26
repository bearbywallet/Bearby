import 'dart:math';
import 'package:flutter/material.dart';

enum ShapeType {
  circle,
  star,
  star6,
  star8,
  triangle,
  triangleDown,
  square,
  diamond,
  pentagon,
  hexagon,
  octagon,
  heart,
  crescent,
  cross,
  plus
}

class ShapeConfig {
  final Color color;
  final double tx;
  final double ty;
  final double rotation;
  final double scale;
  final ShapeType type;

  const ShapeConfig({
    required this.color,
    required this.tx,
    required this.ty,
    required this.rotation,
    required this.scale,
    required this.type,
  });
}

class Jazzicon extends StatefulWidget {
  final double diameter;
  final String seed;
  final int shapeCount;
  final Function()? onClick;

  const Jazzicon({
    super.key,
    required this.diameter,
    required this.seed,
    this.shapeCount = 15,
    this.onClick,
  });

  @override
  State<Jazzicon> createState() => _JazziconState();
}

class _JazziconState extends State<Jazzicon> {
  static const List<Color> _colors = [
    Color(0xFFFF007A), Color(0xFFFF1A8C), Color(0xFFFF339E), Color(0xFFFF4DB0), Color(0xFFFF66C2),
    Color(0xFFAC59FF), Color(0xFFB66CFF), Color(0xFFC07FFF), Color(0xFFCA92FF), Color(0xFFD4A5FF),
    Color(0xFF00D4FF), Color(0xFF1AD9FF), Color(0xFF33DEFF), Color(0xFF4DE3FF), Color(0xFF66E8FF),
    Color(0xFFFF6B35), Color(0xFFFF7D4D), Color(0xFFFF8F66), Color(0xFFFFA17F), Color(0xFFFFB399),
    Color(0xFF43CC71), Color(0xFF56D183), Color(0xFF69D695), Color(0xFF7CDBA7), Color(0xFF8FE0B9),
    Color(0xFFFFD700), Color(0xFFFFDB1A), Color(0xFFFFDF33), Color(0xFFFFE34D), Color(0xFFFFE766),
    Color(0xFF8B5CF6), Color(0xFF9B70F7), Color(0xFFAB84F8), Color(0xFFBB98F9), Color(0xFFCBACFA),
    Color(0xFFEC4899), Color(0xFFEE5CA5), Color(0xFFF070B1), Color(0xFFF284BD), Color(0xFFF498C9),
    Color(0xFF10B981), Color(0xFF24C290), Color(0xFF38CB9F), Color(0xFF4CD4AE), Color(0xFF60DDBD),
    Color(0xFFF59E0B), Color(0xFFF6A922), Color(0xFFF7B439), Color(0xFFF8BF50), Color(0xFFF9CA67),
    Color(0xFF6366F1), Color(0xFF7477F2), Color(0xFF8588F3), Color(0xFF9699F4), Color(0xFFA7AAF5),
    Color(0xFFEF4444), Color(0xFFF05757), Color(0xFFF16A6A), Color(0xFFF27D7D), Color(0xFFF39090),
    Color(0xFF14B8A6), Color(0xFF28C1B5), Color(0xFF3CCAC4), Color(0xFF50D3D3), Color(0xFF64DCE2),
    Color(0xFFF97316), Color(0xFFFA832D), Color(0xFFFB9344), Color(0xFFFCA35B), Color(0xFFFDB372),
    Color(0xFF8B5A3C), Color(0xFF996853), Color(0xFFA7766A), Color(0xFFB58481), Color(0xFFC39298),
    Color(0xFF2DD4BF), Color(0xFF41D9C8), Color(0xFF55DED1), Color(0xFF69E3DA), Color(0xFF7DE8E3),
    Color(0xFFFB923C), Color(0xFFFC9D53), Color(0xFFFDA86A), Color(0xFFFEB381), Color(0xFFFFBE98),
    Color(0xFFC026D3), Color(0xFFC63AD9), Color(0xFFCC4EDF), Color(0xFFD262E5), Color(0xFFD876EB),
    Color(0xFF38BDF8), Color(0xFF4CC4F9), Color(0xFF60CBFA), Color(0xFF74D2FB), Color(0xFF88D9FC),
    Color(0xFFFBBF24), Color(0xFFFCC43B), Color(0xFFCDC952), Color(0xFFFECE69), Color(0xFFFFD380),
    Color(0xFFA78BFA), Color(0xFFB39DFB), Color(0xFFBFAFFC), Color(0xFFCBC1FD), Color(0xFFD7D3FE),
    Color(0xFFF472B6), Color(0xFFF686C2), Color(0xFFF89ACE), Color(0xFFFAADDA), Color(0xFFFCC1E6),
    Color(0xFF34D399), Color(0xFF48D9A7), Color(0xFF5CDFB5), Color(0xFF70E5C3), Color(0xFF84EBD1),
    Color(0xFFFBBF24), Color(0xFFCCC53B), Color(0xFFFDCB52), Color(0xFFFED169), Color(0xFFFFD780),
    Color(0xFF818CF8), Color(0xFF9299F9), Color(0xFFA3A6FA), Color(0xFFB4B3FB), Color(0xFFC5C0FC),
  ];

  static const List<ShapeType> _shapeTypes = [
    ShapeType.circle, ShapeType.star, ShapeType.star6, ShapeType.star8,
    ShapeType.triangle, ShapeType.triangleDown, ShapeType.square, ShapeType.diamond,
    ShapeType.pentagon, ShapeType.hexagon, ShapeType.octagon, ShapeType.heart,
    ShapeType.crescent, ShapeType.cross, ShapeType.plus
  ];

  static const int _colorDistanceThresholdSquared = 6400;
  static const double _twoPi = 2.0 * pi;

  late List<ShapeConfig> _shapes;
  late Color _backgroundColor;
  late Random _random;

  @override
  void initState() {
    super.initState();
    _generateShapes();
  }

  @override
  void didUpdateWidget(Jazzicon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != oldWidget.seed || widget.diameter != oldWidget.diameter || widget.shapeCount != oldWidget.shapeCount) {
      _generateShapes();
    }
  }

  int _generateSeedFromString(String str) {
    int hash = 5381;
    final len = str.length;
    for (int i = 0; i < len; i++) {
      hash = ((hash << 5) ^ hash ^ str.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  int _colorDistanceSquared(Color color1, Color color2) {
    final int r1 = (color1.r * 255).toInt();
    final int g1 = (color1.g * 255).toInt();
    final int b1 = (color1.b * 255).toInt();
    final int r2 = (color2.r * 255).toInt();
    final int g2 = (color2.g * 255).toInt();
    final int b2 = (color2.b * 255).toInt();
    final int dr = r2 - r1;
    final int dg = g2 - g1;
    final int db = b2 - b1;
    return dr * dr + dg * dg + db * db;
  }

  Color _genColor(List<bool> usedColors, {Color? previousColor}) {
    final availableIndices = <int>[];
    final int colorsLen = _colors.length;

    for (int i = 0; i < colorsLen; i++) {
      if (usedColors[i]) continue;
      final color = _colors[i];
      if (previousColor != null && _colorDistanceSquared(color, previousColor) < _colorDistanceThresholdSquared) {
        continue;
      }
      availableIndices.add(i);
    }

    if (availableIndices.isEmpty) {
      usedColors.fillRange(0, colorsLen, false);
      final idx = _random.nextInt(colorsLen);
      usedColors[idx] = true;
      return _colors[idx];
    }

    final idx = availableIndices[_random.nextInt(availableIndices.length)];
    usedColors[idx] = true;
    return _colors[idx];
  }

  ShapeType _genShapeType() {
    return _shapeTypes[_random.nextInt(_shapeTypes.length)];
  }

  void _generateShapes() {
    if (widget.seed.isEmpty) {
      _shapes = [];
      _backgroundColor = Colors.grey;
      return;
    }

    _random = Random(_generateSeedFromString(widget.seed));
    final usedColors = List<bool>.filled(_colors.length, false);

    _backgroundColor = _genColor(usedColors);
    final shapeConfigs = <ShapeConfig>[];

    final double maxRadius = widget.diameter / 2.2;
    final double centerThreshold = maxRadius * 0.3;
    final int shapeCountMinusOne = widget.shapeCount - 1;

    for (int i = 0; i < shapeCountMinusOne; i++) {
      final double firstRot = _random.nextDouble();
      final double angle = _twoPi * firstRot;
      final double radiusRandom = _random.nextDouble();
      final double distanceFromCenter = pow(radiusRandom, 0.7) * maxRadius;

      final double tx = cos(angle) * distanceFromCenter;
      final double ty = sin(angle) * distanceFromCenter;

      final double secondRot = _random.nextDouble();
      final double rotation = firstRot * 360.0 + secondRot * 180.0;

      final double scaleRandom = _random.nextDouble();
      final double scaleBase = 0.25 + scaleRandom * 0.7;
      final double centerBoost = distanceFromCenter < centerThreshold ? 1.2 : 1.0;
      final double scale = scaleBase * centerBoost;

      final previousColor = shapeConfigs.isEmpty ? _backgroundColor : shapeConfigs.last.color;

      shapeConfigs.add(ShapeConfig(
        color: _genColor(usedColors, previousColor: previousColor),
        tx: tx,
        ty: ty,
        rotation: rotation,
        scale: scale,
        type: _genShapeType()
      ));
    }

    setState(() {
      _shapes = shapeConfigs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double center = widget.diameter * 0.5;

    return GestureDetector(
      onTap: widget.onClick,
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _backgroundColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: _shapes.map((shape) {
            return Positioned(
              left: center + shape.tx - (widget.diameter * shape.scale * 0.5),
              top: center + shape.ty - (widget.diameter * shape.scale * 0.5),
              child: Transform.rotate(
                angle: shape.rotation * pi / 180.0,
                child: _ShapeWidget(
                  type: shape.type,
                  color: shape.color,
                  size: widget.diameter * shape.scale,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ShapeWidget extends StatelessWidget {
  final ShapeType type;
  final Color color;
  final double size;

  const _ShapeWidget({
    required this.type,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        );
      case ShapeType.square:
        return Container(
          width: size,
          height: size,
          color: color,
        );
      case ShapeType.diamond:
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size * 0.707,
            height: size * 0.707,
            color: color,
          ),
        );
      case ShapeType.triangle:
      case ShapeType.triangleDown:
      case ShapeType.star:
      case ShapeType.star6:
      case ShapeType.star8:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.octagon:
      case ShapeType.heart:
      case ShapeType.crescent:
      case ShapeType.cross:
      case ShapeType.plus:
        return CustomPaint(
          size: Size(size, size),
          painter: _ShapePainter(type: type, color: color),
        );
    }
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeType type;
  final Color color;

  _ShapePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = _buildPath(size);
    canvas.drawPath(path, paint);
  }

  Path _buildPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    switch (type) {
      case ShapeType.triangle:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
      case ShapeType.triangleDown:
        path.moveTo(w * 0.5, h);
        path.lineTo(0, 0);
        path.lineTo(w, 0);
        path.close();
        break;
      case ShapeType.star:
        _buildStar(path, w, h, 5);
        break;
      case ShapeType.star6:
        _buildStar(path, w, h, 6);
        break;
      case ShapeType.star8:
        _buildStar(path, w, h, 8);
        break;
      case ShapeType.pentagon:
        _buildPolygon(path, w, h, 5);
        break;
      case ShapeType.hexagon:
        _buildPolygon(path, w, h, 6);
        break;
      case ShapeType.octagon:
        _buildPolygon(path, w, h, 8);
        break;
      case ShapeType.heart:
        final cx = w * 0.5;
        path.moveTo(cx, h);
        path.cubicTo(cx, h, w * 0.2, h * 0.6, w * 0.2, h * 0.4);
        path.cubicTo(w * 0.2, h * 0.25, w * 0.3, h * 0.15, w * 0.4, h * 0.15);
        path.cubicTo(w * 0.45, h * 0.15, cx, h * 0.2, cx, h * 0.2);
        path.cubicTo(cx, h * 0.2, w * 0.55, h * 0.15, w * 0.6, h * 0.15);
        path.cubicTo(w * 0.7, h * 0.15, w * 0.8, h * 0.25, w * 0.8, h * 0.4);
        path.cubicTo(w * 0.8, h * 0.6, cx, h, cx, h);
        path.close();
        break;
      case ShapeType.crescent:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        path.addOval(Rect.fromLTWH(w * 0.1, 0, w * 0.85, h));
        path.fillType = PathFillType.evenOdd;
        break;
      case ShapeType.cross:
        final third = w / 3;
        path.moveTo(third, 0);
        path.lineTo(third * 2, 0);
        path.lineTo(third * 2, third);
        path.lineTo(w, third);
        path.lineTo(w, third * 2);
        path.lineTo(third * 2, third * 2);
        path.lineTo(third * 2, h);
        path.lineTo(third, h);
        path.lineTo(third, third * 2);
        path.lineTo(0, third * 2);
        path.lineTo(0, third);
        path.lineTo(third, third);
        path.close();
        break;
      case ShapeType.plus:
        final fifth = w / 5;
        path.moveTo(fifth * 2, 0);
        path.lineTo(fifth * 3, 0);
        path.lineTo(fifth * 3, fifth * 2);
        path.lineTo(w, fifth * 2);
        path.lineTo(w, fifth * 3);
        path.lineTo(fifth * 3, fifth * 3);
        path.lineTo(fifth * 3, h);
        path.lineTo(fifth * 2, h);
        path.lineTo(fifth * 2, fifth * 3);
        path.lineTo(0, fifth * 3);
        path.lineTo(0, fifth * 2);
        path.lineTo(fifth * 2, fifth * 2);
        path.close();
        break;
      default:
        break;
    }
    return path;
  }

  void _buildStar(Path path, double w, double h, int points) {
    final cx = w * 0.5;
    final cy = h * 0.5;
    final outerRadius = w * 0.5;
    final innerRadius = w * 0.2;
    final angleStep = pi / points;
    final totalPoints = points << 1;

    for (int i = 0; i < totalPoints; i++) {
      final radius = (i & 1) == 0 ? outerRadius : innerRadius;
      final angle = angleStep * i - pi * 0.5;
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  void _buildPolygon(Path path, double w, double h, int points) {
    final cx = w * 0.5;
    final cy = h * 0.5;
    final radius = w * 0.45;
    final angleStep = (2 * pi) / points;

    for (int i = 0; i < points; i++) {
      final angle = angleStep * i - pi * 0.5;
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) {
    return type != oldDelegate.type || color != oldDelegate.color;
  }
}
