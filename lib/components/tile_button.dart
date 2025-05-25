import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class TileButton extends StatefulWidget {
  final String? title;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool disabled;

  const TileButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.title,
    this.backgroundColor = const Color(0xFF2C2C2E),
    this.textColor = const Color(0xFF9D4BFF),
    this.disabled = false,
  });

  @override
  State<TileButton> createState() => _TileButtonState();
}

class _TileButtonState extends State<TileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastEaseInToSlowEaseOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastEaseInToSlowEaseOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.disabled) {
      _controller.reverse();
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    if (!widget.disabled) {
      _controller.reverse();
    }
  }

  void _handleHoverChanged(bool isHovered) {
    if (!widget.disabled) {
      setState(() {
        _isHovered = isHovered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    final bool hasTitle = widget.title != null && widget.title!.isNotEmpty;

    final double iconSize = hasTitle ? 34.0 : 20.0;
    final double borderRadius = 16.0;

    double containerSize;

    if (hasTitle) {
      final double estimatedFontSize = theme.caption.fontSize ?? 14.0;
      final double estimatedLineHeightFactor = theme.caption.height ?? 1.3;
      final double actualTextHeightForTwoLines =
          estimatedFontSize * 2 * estimatedLineHeightFactor;

      containerSize =
          12.0 + iconSize + 4.0 + actualTextHeightForTwoLines + 12.0;
    } else {
      containerSize = 48.0;
    }

    Widget buttonContent;

    if (hasTitle) {
      buttonContent = Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Center(child: widget.icon),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title!,
              style: theme.caption.copyWith(
                color: widget.textColor,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      buttonContent = Center(
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: widget.icon,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _handleHoverChanged(true),
      onExit: (_) => _handleHoverChanged(false),
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: widget.disabled ? 0.5 : _opacityAnimation.value,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    // border: Border.all(
                    //     color: theme.primaryPurple.withValues(alpha: 0.2)),
                    boxShadow: [
                      if (_isHovered && !widget.disabled)
                        BoxShadow(
                          color:
                              widget.textColor.withAlpha((0.1 * 255).round()),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: buttonContent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
