import 'package:flutter/material.dart';
import './app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  // AppTheme _currentTheme = LightTheme();
  AppTheme _currentTheme = DarkTheme();

  AppTheme get currentTheme => _currentTheme;

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void toggleTheme() {
    _currentTheme = _currentTheme is DarkTheme ? LightTheme() : DarkTheme();
    notifyListeners();
  }
}
