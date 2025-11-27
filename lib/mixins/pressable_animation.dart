import 'package:flutter/material.dart';

mixin PressableAnimationMixin<T extends StatefulWidget> on State<T>, TickerProvider {
  late AnimationController pressAnimationController;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;

  bool _isHovered = false;
  bool get isHovered => _isHovered;

  void initPressAnimation({
    Duration duration = const Duration(milliseconds: 150),
    double scaleEnd = 0.95,
    double opacityEnd = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    pressAnimationController = AnimationController(
      duration: duration,
      vsync: this,
    );

    scaleAnimation = Tween<double>(
      begin: 1.0,
      end: scaleEnd,
    ).animate(CurvedAnimation(
      parent: pressAnimationController,
      curve: curve,
    ));

    opacityAnimation = Tween<double>(
      begin: 1.0,
      end: opacityEnd,
    ).animate(CurvedAnimation(
      parent: pressAnimationController,
      curve: curve,
    ));
  }

  void disposePressAnimation() {
    pressAnimationController.dispose();
  }

  void handleTapDown([TapDownDetails? details]) {
    pressAnimationController.forward();
  }

  void handleTapUp([TapUpDetails? details]) {
    pressAnimationController.reverse();
  }

  void handleTapCancel() {
    pressAnimationController.reverse();
  }

  void handleHoverEnter([PointerEvent? event]) {
    setState(() => _isHovered = true);
    pressAnimationController.forward(from: 0.5);
  }

  void handleHoverExit([PointerEvent? event]) {
    setState(() => _isHovered = false);
    pressAnimationController.reverse();
  }

  Widget buildPressable({
    required Widget child,
    VoidCallback? onTap,
    bool disabled = false,
    bool enableHover = false,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
  }) {
    Widget gestureChild = GestureDetector(
      behavior: hitTestBehavior,
      onTapDown: disabled ? null : handleTapDown,
      onTapUp: disabled ? null : handleTapUp,
      onTapCancel: disabled ? null : handleTapCancel,
      onTap: disabled ? null : onTap,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, animChild) => Transform.scale(
          scale: scaleAnimation.value,
          child: animChild,
        ),
        child: child,
      ),
    );

    if (enableHover) {
      return MouseRegion(
        onEnter: disabled ? null : handleHoverEnter,
        onExit: disabled ? null : handleHoverExit,
        child: gestureChild,
      );
    }

    return gestureChild;
  }

  Widget buildPressableWithOpacity({
    required Widget child,
    VoidCallback? onTap,
    bool disabled = false,
    bool enableHover = false,
    double disabledOpacity = 0.5,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
  }) {
    Widget gestureChild = GestureDetector(
      behavior: hitTestBehavior,
      onTapDown: disabled ? null : handleTapDown,
      onTapUp: disabled ? null : handleTapUp,
      onTapCancel: disabled ? null : handleTapCancel,
      onTap: disabled ? null : onTap,
      child: AnimatedBuilder(
        animation: pressAnimationController,
        builder: (context, animChild) => Transform.scale(
          scale: disabled ? 1.0 : scaleAnimation.value,
          child: Opacity(
            opacity: disabled ? disabledOpacity : opacityAnimation.value,
            child: animChild,
          ),
        ),
        child: child,
      ),
    );

    if (enableHover) {
      return MouseRegion(
        onEnter: disabled ? null : handleHoverEnter,
        onExit: disabled ? null : handleHoverExit,
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: gestureChild,
      );
    }

    return gestureChild;
  }
}
