import 'package:flutter/material.dart';

enum AppTheme { system, dark, light }

class AppState extends ChangeNotifier {
  AppTheme _currentThemeMode = AppTheme.system;

  ThemeData get currentTheme {
    switch (_currentThemeMode) {
      case AppTheme.light:
        return ThemeData.light();
      case AppTheme.dark:
        return ThemeData.dark();
      case AppTheme.system:
        return ThemeData.dark();
    }
  }

  void setTheme(AppTheme theme) {
    _currentThemeMode = theme;
    notifyListeners();
  }

  Future<void> initialize() async {
    // TODO: init theme form storage
  }
}
