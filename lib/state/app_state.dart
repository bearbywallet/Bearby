import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';

enum AppTheme { system, dark, light }

class AppState extends ChangeNotifier {
  AppTheme _currentThemeMode = AppTheme.system;
  BackgroundState _state;
  int _selectedWallet = 0;

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

  void setSelectedWallet(int index) {
    _selectedWallet = index;
    notifyListeners();
  }

  List<WalletInfo> get wallets {
    return _state.wallets;
  }

  WalletInfo? get wallet {
    return _state.wallets[_selectedWallet];
  }

  AccountInfo? get account {
    if (wallet == null) {
      return null;
    }

    int index = wallet!.selectedAccount.toInt();

    return wallet!.accounts[index];
  }

  int get selectedWallet {
    return _selectedWallet;
  }

  Future<void> syncData() async {
    _state = await getData();
    notifyListeners();
  }

  Future<void> initialize() async {
    // TODO: init theme form storage
  }
}
