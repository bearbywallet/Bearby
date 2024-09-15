import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class HoverSvgIcon extends StatefulWidget {
  final String assetName;
  final double width;
  final double height;
  final VoidCallback onTap;

  const HoverSvgIcon({
    Key? key,
    required this.assetName,
    required this.width,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  _HoverSvgIconState createState() => _HoverSvgIconState();
}

class _HoverSvgIconState extends State<HoverSvgIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Opacity(
        opacity: _isPressed ? 0.5 : 1.0,
        child: SvgPicture.asset(
          widget.assetName,
          width: widget.width,
          height: widget.height,
          color: theme.textPrimary,
        ),
      ),
    );
  }
}
