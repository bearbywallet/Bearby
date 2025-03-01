import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/pages/add_account.dart';
import 'package:zilpay/pages/add_token.dart';
import 'package:zilpay/pages/address_book.dart';
import 'package:zilpay/pages/appearance.dart';
import 'package:zilpay/pages/currency_conversion.dart';
import 'package:zilpay/pages/ledger_connect.dart';
import 'package:zilpay/pages/locale.dart';
import 'package:zilpay/pages/network.dart';
import 'package:zilpay/pages/notification.dart';
import 'package:zilpay/pages/password_setup.dart';
import 'package:zilpay/pages/receive.dart';
import 'package:zilpay/pages/restore_bip39.dart';
import 'package:zilpay/pages/restore_rkstorage.dart';
import 'package:zilpay/pages/reveal_bip39.dart';
import 'package:zilpay/pages/reveal_sk.dart';
import 'package:zilpay/pages/security.dart';
import 'package:zilpay/pages/send.dart';
import 'package:zilpay/pages/setup_cipher.dart';
import 'package:zilpay/pages/setup_net.dart';
import 'package:zilpay/pages/sk_gen.dart';
import 'package:zilpay/pages/verify_bip39.dart';
import 'package:zilpay/pages/wallet.dart';
import 'package:zilpay/pages/web_view.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'pages/main_page.dart';
import 'pages/login_page.dart';
import 'pages/initial_page.dart';
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
      '/ledger_connect',
      '/wallet',
      '/appearance',
      '/restore_bip39',
      '/currency',
      '/notifications',
      '/language',
      '/address-book',
      '/security',
      '/networks',
      '/send',
      '/receive',
      '/add_token',
      '/reveal_sk',
      '/reveal_bip39',
      '/add_account',
      '/web_view',
      '/rk_restore'
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
          case '/rk_restore':
            return wrapWithProviders(const RestoreRKStorage());
          case '/restore_bip39':
            return wrapWithProviders(const RestoreSecretPhrasePage());
          case '/cipher_setup':
            return wrapWithProviders(const CipherSettingsPage());
          case '/net_setup':
            return wrapWithProviders(const SetupNetworkSettingsPage());
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
          case '/web_view':
            return wrapWithProviders(const WebViewPage(initialUrl: ''));
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
          case '/rk_restore':
            return wrapWithProviders(const RestoreRKStorage());
          case '/cipher_setup':
            return wrapWithProviders(const CipherSettingsPage());
          case '/net_setup':
            return wrapWithProviders(const SetupNetworkSettingsPage());
          case '/gen_sk':
            return wrapWithProviders(const SecretKeyGeneratorPage());
          case '/gen_bip39':
            return wrapWithProviders(const SecretPhraseGeneratorPage());
          case '/verify_bip39':
            return wrapWithProviders(const SecretPhraseVerifyPage());
          case '/restore_bip39':
            return wrapWithProviders(const RestoreSecretPhrasePage());
          case '/restore_options':
            return wrapWithProviders(const RestoreWalletOptionsPage());
          case '/gen_options':
            return wrapWithProviders(const GenWalletOptionsPage());
          case '/new_wallet_options':
            return wrapWithProviders(const AddWalletOptionsPage());
          case '/initial':
            return wrapWithProviders(const InitialPage());
          case '/web_view':
            return wrapWithProviders(const WebViewPage(initialUrl: ''));
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
      case '/receive':
        return wrapWithProviders(const ReceivePage());
      case '/add_account':
        return wrapWithProviders(const AddAccount());
      case '/add_token':
        return wrapWithProviders(const AddTokenPage());
      case '/send':
        return wrapWithProviders(const SendTokenPage());
      case '/reveal_sk':
        return wrapWithProviders(const RevealSecretKey());
      case '/reveal_bip39':
        return wrapWithProviders(const RevealSecretPhrase());
      case '/browser':
        return wrapWithProviders(const BrowserPage());
      case '/wallet':
        return wrapWithProviders(const WalletPage());
      case '/appearance':
        return wrapWithProviders(const AppearanceSettingsPage());
      case '/notifications':
        return wrapWithProviders(const NotificationsSettingsPage());
      case '/address-book':
        return wrapWithProviders(const AddressBookPage());
      case '/language':
        return wrapWithProviders(const LanguagePage());
      case '/networks':
        return wrapWithProviders(const NetworkPage());
      case '/security':
        return wrapWithProviders(const SecurityPage());
      case '/settings':
        return wrapWithProviders(const SettingsPage());
      case '/currency':
        return wrapWithProviders(const CurrencyConversionPage());
      case '/pass_setup':
        return wrapWithProviders(const PasswordSetupPage());
      case '/cipher_setup':
        return wrapWithProviders(const CipherSettingsPage());
      case '/rk_restore':
        return wrapWithProviders(const RestoreRKStorage());
      case '/net_setup':
        return wrapWithProviders(const SetupNetworkSettingsPage());
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
      case '/restore_bip39':
        return wrapWithProviders(const RestoreSecretPhrasePage());
      case '/initial':
        return wrapWithProviders(const InitialPage());
      case '/web_view':
        final uri =
            Uri.tryParse(settings.name?.replaceFirst('/web_view?', '') ?? '') ??
                Uri();
        return wrapWithProviders(
            WebViewPage(initialUrl: uri.queryParameters['url'] ?? ''));
      default:
        return wrapWithProviders(const MainPage());
    }
  }
}
