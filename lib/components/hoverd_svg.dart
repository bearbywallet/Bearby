import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class HoverSvgIcon extends StatefulWidget {
  final String assetName;
  final double width;
  final double height;
  final VoidCallback onTap;
  final Color? color;
  final EdgeInsets? padding;
  final BlendMode? blendMode;

  const HoverSvgIcon({
    super.key,
    required this.assetName,
    required this.width,
    required this.height,
    required this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(8.0),
    this.blendMode,
  });

  @override
  State<HoverSvgIcon> createState() => HoverSvgIconState();
}

class HoverSvgIconState extends State<HoverSvgIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final iconColor = widget.color ?? theme.textPrimary;
    final effectiveBlendMode = widget.blendMode ?? BlendMode.srcIn;

    return Container(
      constraints: BoxConstraints(
        minWidth: widget.width + 16,
        minHeight: widget.height + 16,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Padding(
          padding: widget.padding!,
          child: Opacity(
            opacity: _isPressed ? 0.5 : 1.0,
            child: SvgPicture.asset(
              widget.assetName,
              width: widget.width,
              height: widget.height,
              colorFilter: ColorFilter.mode(
                iconColor,
                effectiveBlendMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
