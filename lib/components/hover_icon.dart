import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/state/app_state.dart';

class HoverIcon extends StatefulWidget {
  final AppIcon icon;
  final double size;
  final VoidCallback onTap;
  final Color? color;
  final EdgeInsets padding;

  const HoverIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final iconColor = widget.color ?? theme.textPrimary;

    return Container(
      constraints: BoxConstraints(
        minWidth: widget.size + 16,
        minHeight: widget.size + 16,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Padding(
          padding: widget.padding,
          child: Opacity(
            opacity: _isPressed ? 0.5 : 1.0,
            child: AppIconView(
              icon: widget.icon,
              size: widget.size,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
