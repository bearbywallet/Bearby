import 'package:flutter/widgets.dart';

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

  ({
    double containerSize,
    double iconSize,
    double borderRadius,
    double fontSize
  }) _getDynamicSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool hasTitle = widget.title != null && widget.title!.isNotEmpty;

    double baseTextHeight = 2 * 12.0 * 1.5;
    double calculatedBaseContainerHeightForTitle =
        16.0 + 28.0 + 6.0 + baseTextHeight + 16.0;

    double baseContainerSize =
        hasTitle ? calculatedBaseContainerHeightForTitle : 56.0;
    double baseIconSize = hasTitle ? 28.0 : 24.0;
    double baseBorderRadius = hasTitle ? 24.0 : 20.0;
    double baseFontSize = 12.0;

    double sizeMultiplier;
    if (screenWidth < 400) {
      sizeMultiplier = 1.0;
    } else if (screenWidth < 600) {
      sizeMultiplier = 1.1;
    } else if (screenWidth < 900) {
      sizeMultiplier = 1.2;
    } else {
      sizeMultiplier = 1.3;
    }

    return (
      containerSize: baseContainerSize * sizeMultiplier,
      iconSize: baseIconSize * sizeMultiplier,
      borderRadius: baseBorderRadius * sizeMultiplier,
      fontSize: baseFontSize * sizeMultiplier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getDynamicSizes(context);
    final bool hasTitle = widget.title != null && widget.title!.isNotEmpty;

    Widget buttonContent;

    if (hasTitle) {
      buttonContent = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: sizes.iconSize,
                height: sizes.iconSize,
                child: widget.icon,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title!,
              style: TextStyle(
                color: widget.textColor,
                fontSize: sizes.fontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      buttonContent = Center(
        child: SizedBox(
          width: sizes.iconSize,
          height: sizes.iconSize,
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
                  width: sizes.containerSize,
                  height: sizes.containerSize,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(sizes.borderRadius),
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
