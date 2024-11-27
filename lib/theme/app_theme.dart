import 'package:flutter/material.dart';

abstract class AppTheme {
  Color get primaryPurple;
  Color get secondaryPurple;
  Color get background;
  Color get cardBackground;
  Color get textPrimary;
  Color get textSecondary;
  Color get buttonBackground;
  Color get buttonText;
  Color get danger;
  Color get success;

  Color get gradientStart;
  Color get gradientMiddle;
  Color get gradientEnd;
}

class DarkTheme implements AppTheme {
  @override
  Color get primaryPurple => const Color(0xFF8A2BE2);
  @override
  Color get secondaryPurple => const Color(0xFFB23AEE);
  @override
  Color get background => Colors.black;
  @override
  Color get cardBackground => const Color(0xFF0D1117);
  @override
  Color get textPrimary => Colors.white;
  @override
  Color get textSecondary => const Color(0xFFB3B3B3);
  @override
  Color get buttonBackground => const Color(0xFF3A3A3A);
  @override
  Color get buttonText => const Color(0xFFE0E0E0);
  @override
  Color get danger => const Color(0xFFE94560);
  @override
  Color get success => const Color(0xFF4CAF50);

  @override
  Color get gradientStart => const Color(0xFF4A0E4E);
  @override
  Color get gradientMiddle => const Color(0xFF220A23);
  @override
  Color get gradientEnd => Colors.black;
}

class LightTheme implements AppTheme {
  @override
  Color get primaryPurple => const Color(0xFF6A1B9A);
  @override
  Color get secondaryPurple => const Color(0xFF9C27B0);
  @override
  Color get background => const Color(0xFFF5F5F5);
  @override
  Color get cardBackground => Colors.white;
  @override
  Color get textPrimary => const Color(0xFF212121);
  @override
  Color get textSecondary => const Color(0xFF757575);
  @override
  Color get buttonBackground => const Color(0xFFE0E0E0);
  @override
  Color get buttonText => const Color(0xFF212121);
  @override
  Color get danger => const Color(0xFFD32F2F);
  @override
  Color get success => const Color(0xFF2E7D32);

  @override
  Color get gradientStart => const Color(0xFFE6E6FA);
  @override
  Color get gradientMiddle => const Color(0xFFD8BFD8);
  @override
  Color get gradientEnd => const Color(0xFFF0F8FF);
}
