import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/pages/ledger_connect.dart';
import 'package:zilpay/pages/password_setup.dart';
import 'package:zilpay/pages/setup_cipher.dart';
import 'package:zilpay/pages/setup_net.dart';
import 'package:zilpay/pages/sk_gen.dart';
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

    return wrapWithProviders(const MainPage());

    final List<String> setupRoutes = [
      '/pass_setup',
      '/cipher_setup',
      '/net_setup',
      '/gen_bip39',
      '/gen_sk',
      '/verify_bip39',
      '/restore_options',
      '/gen_options',
      '/new_wallet_options',
      '/initial',
      '/ledger_connect'
    ];

    if (settings.name == '/ledger_connect') {
      return wrapWithProviders(const LedgerConnectPage());
    }

    if (settings.name == '/' || settings.name == null) {
      if (!authGuard.ready) {
        return wrapWithProviders(const InitialPage());
      } else if (!authGuard.enabled) {
        return wrapWithProviders(const LoginPage());
      } else {
        return wrapWithProviders(const MainPage());
      }
    }

    if (!authGuard.ready) {
      if (setupRoutes.contains(settings.name)) {
        switch (settings.name) {
          case '/pass_setup':
            return wrapWithProviders(const PasswordSetupPage());
          case '/cipher_setup':
            return wrapWithProviders(const CipherSettingsPage());
          case '/net_setup':
            return wrapWithProviders(const BlockchainSettingsPage());
          case '/gen_bip39':
            return wrapWithProviders(const SecretPhraseGeneratorPage());
          case '/gen_sk':
            return wrapWithProviders(const SecretKeyGeneratorPage());
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
      return wrapWithProviders(const InitialPage());
    }

    if (!authGuard.enabled) {
      if (settings.name == '/login') {
        return wrapWithProviders(const LoginPage());
      }

      if (setupRoutes.contains(settings.name)) {
        switch (settings.name) {
          case '/pass_setup':
            return wrapWithProviders(const PasswordSetupPage());
          case '/cipher_setup':
            return wrapWithProviders(const CipherSettingsPage());
          case '/net_setup':
            return wrapWithProviders(const BlockchainSettingsPage());
          case '/gen_sk':
            return wrapWithProviders(const SecretKeyGeneratorPage());
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
            return wrapWithProviders(const LoginPage());
        }
      }
      return wrapWithProviders(const LoginPage());
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
      case '/pass_setup':
        return wrapWithProviders(const PasswordSetupPage());
      case '/cipher_setup':
        return wrapWithProviders(const CipherSettingsPage());
      case '/net_setup':
        return wrapWithProviders(const BlockchainSettingsPage());
      case '/gen_sk':
        return wrapWithProviders(const SecretKeyGeneratorPage());
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
        return wrapWithProviders(const MainPage());
    }
  }
}
