import 'package:flutter/material.dart';

class ChunkedAddressText extends StatelessWidget {
  final String address;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle style;

  const ChunkedAddressText({
    super.key,
    required this.address,
    required this.primaryColor,
    required this.secondaryColor,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final chunkCount = (address.length + 3) ~/ 4;
    final primaryStyle = style.copyWith(
      color: primaryColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final secondaryStyle = style.copyWith(
      color: secondaryColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final spans = List<TextSpan>.generate(chunkCount, (index) {
      final start = index * 4;
      final end = (start + 4 < address.length) ? start + 4 : address.length;
      final text = address.substring(start, end);

      return TextSpan(
        text: index == chunkCount - 1 ? text : '$text ',
        style: index.isEven ? primaryStyle : secondaryStyle,
      );
    });

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}
