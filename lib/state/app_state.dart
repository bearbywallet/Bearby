import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';

enum AppTheme { system, dark, light }

class AppState extends ChangeNotifier {
  AppTheme _currentThemeMode = AppTheme.system;
  BackgroundState _state;

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

  AppState({required BackgroundState state}) : _state = state;

  void setTheme(AppTheme theme) {
    _currentThemeMode = theme;
    notifyListeners();
  }

  List<WalletInfo> get wallets {
    return _state.wallets;
  }

  Future<void> syncData() async {
    _state = await getData();
    notifyListeners();
  }

  Future<void> initialize() async {
    // TODO: init theme form storage
  }
}
