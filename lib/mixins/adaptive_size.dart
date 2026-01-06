import 'package:flutter/material.dart';

class AdaptiveSize {
  static const double _smallScreenThreshold = 400.0;
  static const double _baseWidth = 340.0;
  static const double _minScale = 0.85;
  static const double _maxScale = 1.9;

  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= _smallScreenThreshold) {
      return 1.0;
    }

    final scale = screenWidth / _baseWidth;
    return scale.clamp(_minScale, _maxScale);
  }

  static double getAdaptivePadding(
      BuildContext context, double defaultPadding) {
    final size = MediaQuery.of(context).size;

    if (size.width <= 375) {
      return defaultPadding / 2;
    }

    return defaultPadding * getScaleFactor(context);
  }

  static double getAdaptiveSize(BuildContext context, double defaultSize) {
    return defaultSize * getScaleFactor(context);
  }

  static double getAdaptiveFontSize(BuildContext context, double defaultSize) {
    final scale = getScaleFactor(context);
    return (defaultSize * scale).clamp(defaultSize * 0.85, defaultSize * 1.2);
  }

  static double getAdaptiveButtonScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= _smallScreenThreshold) {
      return 1.0;
    }
    final scale = screenWidth / _baseWidth;
    return scale.clamp(1.0, 1.15);
  }

  static double getAdaptiveIconSize(BuildContext context, double defaultSize) {
    final scale = getScaleFactor(context);
    return (defaultSize * scale).clamp(defaultSize * 0.9, defaultSize * 1.3);
  }

  static double getAdaptiveRadius(BuildContext context, double defaultRadius) {
    final scale = getScaleFactor(context);
    return (defaultRadius * scale).clamp(defaultRadius, defaultRadius * 1.2);
  }

  static EdgeInsets getAdaptiveEdgeInsets(
      BuildContext context, EdgeInsets defaultInsets) {
    final scale = getScaleFactor(context);
    return EdgeInsets.only(
      left: defaultInsets.left * scale,
      top: defaultInsets.top * scale,
      right: defaultInsets.right * scale,
      bottom: defaultInsets.bottom * scale,
    );
  }
}
