import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/pages/password_setup.dart';
import 'package:zilpay/pages/setup_cipher.dart';
import 'package:zilpay/pages/setup_net.dart';
import 'package:zilpay/pages/verify_bip39.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'pages/main_page.dart';
import 'pages/login_page.dart';
import 'pages/initial_page.dart';
import 'pages/history_page.dart';
import 'pages/browser_page.dart';
import 'pages/settings_page.dart';
import 'pages/new_wallet_options.dart';
import 'pages/gen_wallet_options.dart';
import 'pages/wallet_restore_options.dart';
import './pages/gen_bip39.dart';

class AppRouter {
  final AuthGuard authGuard;
  final AppState appState;

  AppRouter({required this.authGuard, required this.appState});

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _buildRoute(context, settings),
    );
  }

  Widget _buildRoute(BuildContext context, RouteSettings settings) {
    Widget wrapWithProviders(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authGuard),
          ChangeNotifierProvider.value(value: appState),
        ],
        child: child,
      );
    }

    if (!authGuard.enabled) {
      switch (settings.name) {
        case '/login':
          if (authGuard.ready) {
            return wrapWithProviders(const LoginPage());
          } else {
            return wrapWithProviders(const InitialPage());
          }
        case '/pass_setup':
          return wrapWithProviders(const PasswordSetupPage());
        case '/cipher_setup':
          return wrapWithProviders(const CipherSettingsPage());
        case '/net_setup':
          return wrapWithProviders(const BlockchainSettingsPage());
        case '/gen_bip39':
          return wrapWithProviders(const SecretPhraseGeneratorPage());
        case '/verify_bip39':
          return wrapWithProviders(const SecretPhraseVerifyPage());
        case '/restore_options':
          return wrapWithProviders(const RestoreWalletOptionsPage());
        case '/gen_options':
          return wrapWithProviders(const GenWalletOptionsPage());
        case '/new_wallet_options':
          return wrapWithProviders(const AddWalletOptionsPage());
        case '/initial':
          return wrapWithProviders(const InitialPage());
        default:
          return wrapWithProviders(const InitialPage());
      }
    }

    switch (settings.name) {
      case '/login':
        return wrapWithProviders(const LoginPage());
      case '/':
        return wrapWithProviders(const MainPage());
      case '/history':
        return wrapWithProviders(const HistoryPage());
      case '/browser':
        return wrapWithProviders(const BrowserPage());
      case '/settings':
        return wrapWithProviders(const SettingsPage());
      default:
        return wrapWithProviders(const MainPage());
    }
  }
}
