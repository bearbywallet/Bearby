import 'package:flutter/material.dart';
import './app_theme.dart';

enum ThemeState { system, dark, light }

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeState _state = ThemeState.system;
  Brightness _systemBrightness =
      WidgetsBinding.instance.window.platformBrightness;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _systemBrightness = WidgetsBinding.instance.window.platformBrightness;
    notifyListeners();
  }

  ThemeState get state {
    return _state;
  }

  AppTheme get currentTheme {
    switch (_state) {
      case ThemeState.system:
        return _systemBrightness == Brightness.dark
            ? DarkTheme()
            : LightTheme();
      case ThemeState.dark:
        return DarkTheme();
      case ThemeState.light:
        return LightTheme();
    }
  }

  void setTheme(ThemeState theme) {
    _state = theme;
    notifyListeners();
  }
}
