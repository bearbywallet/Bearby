import 'dart:ui';

Color getWalletColor(int index) {
  final colors = [
    const Color(0xFF55A2F2),
    const Color(0xFFFFB347),
    const Color(0xFF4ECFB0),
  ];

  return colors[index % colors.length];
}

String hexStrToColor(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}
