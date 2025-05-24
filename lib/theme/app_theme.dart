import 'package:flutter/material.dart';

abstract class AppTheme {
  String value = "Dark";

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
  Color get warning;

  Color get gradientStart;
  Color get gradientMiddle;
  Color get gradientEnd;

  Color get modalBorder;

  Brightness get brightness;

  TextStyle get headline1;
  TextStyle get headline2;
  TextStyle get subtitle1;
  TextStyle get bodyText1;
  TextStyle get bodyText2;
  TextStyle get button;
  TextStyle get caption;
  TextStyle get overline;
}

class DarkTheme implements AppTheme {
  @override
  String value = "Dark";

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
  Color get warning => const Color(0xFFFF9800);

  @override
  Color get gradientStart => const Color(0xFF4A0E4E);
  @override
  Color get gradientMiddle => const Color(0xFF220A23);
  @override
  Color get gradientEnd => Colors.black;

  @override
  Color get modalBorder => Colors.grey.withValues(alpha: 0.2);

  @override
  Brightness get brightness => Brightness.light;

  @override
  TextStyle get headline1 => const TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.bold);
  @override
  TextStyle get headline2 => const TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w600);
  @override
  TextStyle get subtitle1 => const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w500);
  @override
  TextStyle get bodyText1 => const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.normal);
  @override
  TextStyle get bodyText2 => const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.normal);
  @override
  TextStyle get button => const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.25);
  @override
  TextStyle get caption => const TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.normal);
  @override
  TextStyle get overline => const TextStyle(fontFamily: 'Roboto', fontSize: 10, fontWeight: FontWeight.normal, letterSpacing: 1.5);
}

class LightTheme implements AppTheme {
  @override
  String value = "Light";

  @override
  Color get primaryPurple => const Color(0xFFFC72FF);
  @override
  Color get secondaryPurple => const Color(0xFFB0B0B0);
  @override
  Color get background => const Color(0xFFFFFFFF);
  @override
  Color get cardBackground => const Color(0xFFF7F7F7);
  @override
  Color get textPrimary => const Color(0xFF000000);
  @override
  Color get textSecondary => const Color(0xFF6C6C6C);
  @override
  Color get buttonBackground => const Color(0xFFFF007A);
  @override
  Color get buttonText => const Color(0xFFFFFFFF);
  @override
  Color get danger => const Color(0xFFFF4D4D);
  @override
  Color get success => const Color(0xFF00D395);
  @override
  Color get warning => const Color(0xFFFFA500);

  @override
  Color get gradientStart => const Color(0xFFFF007A);
  @override
  Color get gradientMiddle => const Color(0xFFD500F9);
  @override
  Color get gradientEnd => const Color(0xFFFF007A);

  @override
  Color get modalBorder => const Color(0xFFE0E0E0);

  @override
  Brightness get brightness => Brightness.light;
}
