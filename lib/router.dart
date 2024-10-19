import 'package:flutter/material.dart';
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
    switch (settings.name) {
      case '/net_setup':
        return MaterialPageRoute(
            builder: (_) => const BlockchainSettingsPage(), settings: settings);
      case '/gen_bip39':
        return MaterialPageRoute(
            builder: (_) => const SecretPhraseGeneratorPage(),
            settings: settings);
      case '/verify_bip39':
        return MaterialPageRoute(
            builder: (_) => const SecretPhraseVerifyPage(), settings: settings);
      case '/restore_options':
        return MaterialPageRoute(
            builder: (_) => RestoreWalletOptionsPage(), settings: settings);
      case '/gen_options':
        return MaterialPageRoute(
            builder: (_) => GenWalletOptionsPage(), settings: settings);
      case '/new_wallet_options':
        return MaterialPageRoute(
            builder: (_) => AddWalletOptionsPage(), settings: settings);
      case '/initial':
        return MaterialPageRoute(
            builder: (_) => InitialPage(), settings: settings);
      case '/login':
        return MaterialPageRoute(
            builder: (_) => LoginPage(), settings: settings);
    }

    if (!authGuard.ready) {
      return MaterialPageRoute(
        builder: (_) => InitialPage(),
        settings: const RouteSettings(name: '/initial'),
      );
    } else if (!authGuard.enabled) {
      return MaterialPageRoute(
        builder: (_) => LoginPage(),
        settings: const RouteSettings(name: '/login'),
      );
    }

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => MainPage(),
          settings: settings,
        );
      case '/history':
        return MaterialPageRoute(
          builder: (_) => HistoryPage(),
          settings: settings,
        );
      case '/browser':
        return MaterialPageRoute(
          builder: (_) => BrowserPage(),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => SettingsPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => MainPage(),
          settings: const RouteSettings(name: '/'),
        );
    }
  }
}
