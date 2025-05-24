import 'package:flutter/material.dart';

class _TextStyles {
  static const String _fontFamily = 'Roboto';

  static const TextStyle headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle bodyText1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle bodyText2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
  );
}

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
  Color get modalBorder => Colors.grey.withOpacity(0.2);

  @override
  Brightness get brightness => Brightness.light;

  @override
  TextStyle get headline1 => _TextStyles.headline1;
  @override
  TextStyle get headline2 => _TextStyles.headline2;
  @override
  TextStyle get subtitle1 => _TextStyles.subtitle1;
  @override
  TextStyle get bodyText1 => _TextStyles.bodyText1;
  @override
  TextStyle get bodyText2 => _TextStyles.bodyText2;
  @override
  TextStyle get button => _TextStyles.button;
  @override
  TextStyle get caption => _TextStyles.caption;
  @override
  TextStyle get overline => _TextStyles.overline;
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

  @override
  TextStyle get headline1 => _TextStyles.headline1;
  @override
  TextStyle get headline2 => _TextStyles.headline2;
  @override
  TextStyle get subtitle1 => _TextStyles.subtitle1;
  @override
  TextStyle get bodyText1 => _TextStyles.bodyText1;
  @override
  TextStyle get bodyText2 => _TextStyles.bodyText2;
  @override
  TextStyle get button => _TextStyles.button;
  @override
  TextStyle get caption => _TextStyles.caption;
  @override
  TextStyle get overline => _TextStyles.overline;
}
