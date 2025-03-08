import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class SettingsItem extends StatefulWidget {
  final String title;
  final String trailingSvgPath;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isGrouped;

  const SettingsItem({
    super.key,
    required this.title,
    required this.trailingSvgPath,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isGrouped = true,
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  bool _isPressed = false;

  BorderRadius? _getBorderRadius() {
    if (widget.isGrouped) {
      if (widget.isFirst && widget.isLast) {
        return BorderRadius.circular(16);
      } else if (widget.isFirst) {
        return const BorderRadius.vertical(top: Radius.circular(16));
      } else if (widget.isLast) {
        return const BorderRadius.vertical(bottom: Radius.circular(16));
      }
    } else {
      return BorderRadius.circular(16);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final borderRadius = _getBorderRadius();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isPressed
              ? theme.background.withValues(alpha: 1.0)
              : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SvgPicture.asset(
              widget.trailingSvgPath,
              colorFilter: ColorFilter.mode(
                theme.textSecondary,
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
