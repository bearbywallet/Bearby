import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBarUtils {
  static SystemUiOverlayStyle getOverlayStyle(BuildContext context) {
    final Color effectiveBgColor = Theme.of(context).scaffoldBackgroundColor;
    final Brightness backgroundBrightness =
        ThemeData.estimateBrightnessForColor(effectiveBgColor);
    final Brightness statusBarIconBrightness =
        backgroundBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
    final Brightness statusBarBrightness = backgroundBrightness;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
    );
  }
}

mixin StatusBarMixin {
  SystemUiOverlayStyle getSystemUiOverlayStyle(BuildContext context) {
    return StatusBarUtils.getOverlayStyle(context);
  }
}
