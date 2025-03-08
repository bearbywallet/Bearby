import 'package:flutter/material.dart';

class AdaptiveSize {
  static double getAdaptivePadding(
      BuildContext context, double defaultPadding) {
    final size = MediaQuery.of(context).size;

    if (size.width <= 375) {
      return defaultPadding / 2;
    }

    return defaultPadding;
  }
}
