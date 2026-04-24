import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'state/app_state.dart';
import 'pages/main_page.dart';
import 'pages/login_page.dart';
import 'pages/initial_page.dart';
import 'pages/home_page.dart';
import 'pages/history_page.dart';
import 'pages/browser_page.dart';
import 'pages/about.dart';
import 'pages/add_account.dart';
import 'pages/add_ledger_account.dart';
import 'pages/add_network.dart';
import 'pages/address_book.dart';
import 'pages/appearance.dart';
import 'pages/browser_settings.dart';
import 'pages/currency_conversion.dart';
import 'pages/gen_bip39.dart';
import 'pages/gen_wallet_options.dart';
import 'pages/keystore_backup.dart';
import 'pages/keystore_file_restore.dart';
import 'pages/ledger_connect.dart';
import 'pages/locale.dart';
import 'pages/manage_tokens.dart';
import 'pages/network.dart';
import 'pages/new_wallet_options.dart';
import 'pages/notification.dart';
import 'pages/password_setup.dart';
import 'pages/receive.dart';
import 'pages/restore_bip39.dart';
import 'pages/restore_sk.dart';
import 'pages/reveal_bip39.dart';
import 'pages/reveal_sk.dart';
import 'pages/security.dart';
import 'pages/send.dart';
import 'pages/settings_page.dart';
import 'pages/setup_net.dart';
import 'pages/sk_gen.dart';
import 'pages/verify_bip39.dart';
import 'pages/wallet.dart';
import 'pages/wallet_restore_options.dart';
import 'pages/zil_stake.dart';

abstract class AppRoutes {
  static const home               = '/';
  static const history            = '/history';
  static const browser            = '/browser';
  static const login              = '/login';
  static const initial            = '/initial';
  static const settings           = '/settings';
  static const about              = '/about';
  static const receive            = '/receive';
  static const addAccount         = '/add_account';
  static const addNetwork         = '/add_network';
  static const manageTokens       = '/manage_tokens';
  static const send               = '/send';
  static const revealSk           = '/reveal_sk';
  static const revealBip39        = '/reveal_bip39';
  static const wallet             = '/wallet';
  static const appearance         = '/appearance';
  static const notifications      = '/notifications';
  static const addressBook        = '/address-book';
  static const language           = '/language';
  static const networks           = '/networks';
  static const security           = '/security';
  static const currency           = '/currency';
  static const passSetup          = '/pass_setup';
  static const netSetup           = '/net_setup';
  static const genSk              = '/gen_sk';
  static const genBip39           = '/gen_bip39';
  static const verifyBip39        = '/verify_bip39';
  static const browserSettings    = '/browser_settings';
  static const keystoreBackup     = '/keystore_backup';
  static const restoreOptions     = '/restore_options';
  static const genOptions         = '/gen_options';
  static const newWalletOptions   = '/new_wallet_options';
  static const restoreBip39       = '/restore_bip39';
  static const restoreSk          = '/restore_sk';
  static const keystoreFileRestore = '/keystore_file_restore';
  static const addLedgerAccount   = '/add_ledger_account';
  static const zilStake           = '/zil_stake';
  static const ledgerConnect      = '/ledger_connect';
}

const _setupRoutes = <String>{
  AppRoutes.passSetup,
  AppRoutes.netSetup,
  AppRoutes.genBip39,
  AppRoutes.genSk,
  AppRoutes.verifyBip39,
  AppRoutes.restoreOptions,
  AppRoutes.genOptions,
  AppRoutes.newWalletOptions,
  AppRoutes.initial,
  AppRoutes.ledgerConnect,
  AppRoutes.wallet,
  AppRoutes.appearance,
  AppRoutes.restoreBip39,
  AppRoutes.currency,
  AppRoutes.notifications,
  AppRoutes.language,
  AppRoutes.addressBook,
  AppRoutes.security,
  AppRoutes.networks,
  AppRoutes.send,
  AppRoutes.receive,
  AppRoutes.revealSk,
  AppRoutes.revealBip39,
  AppRoutes.addAccount,
  AppRoutes.addNetwork,
  AppRoutes.browserSettings,
  AppRoutes.restoreSk,
  AppRoutes.about,
  AppRoutes.keystoreBackup,
  AppRoutes.keystoreFileRestore,
  AppRoutes.addLedgerAccount,
  AppRoutes.zilStake,
  AppRoutes.settings,
  AppRoutes.manageTokens,
};

String? _globalRedirect(
  BuildContext context,
  GoRouterState state,
  AppState appState,
) {
  final loc = state.matchedLocation;

  if (appState.wallets.isEmpty) {
    if (loc == AppRoutes.initial || _setupRoutes.contains(loc)) return null;
    return AppRoutes.initial;
  }

  if (appState.wallet == null) {
    if (loc == AppRoutes.login || _setupRoutes.contains(loc)) return null;
    return AppRoutes.login;
  }

  if (loc == AppRoutes.login || loc == AppRoutes.initial) {
    return AppRoutes.home;
  }

  return null;
}

GoRouter createRouter(AppState appState) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: appState,
    redirect: (context, state) => _globalRedirect(context, state, appState),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainPage(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (_, __) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.browser,
                builder: (_, __) => const BrowserPage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(path: AppRoutes.login,   builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.initial, builder: (_, __) => const InitialPage()),

      GoRoute(path: AppRoutes.settings,       builder: (_, __) => const SettingsPage()),
      GoRoute(path: AppRoutes.about,          builder: (_, __) => const AboutPage()),
      GoRoute(path: AppRoutes.appearance,     builder: (_, __) => const AppearanceSettingsPage()),
      GoRoute(path: AppRoutes.notifications,  builder: (_, __) => const NotificationsSettingsPage()),
      GoRoute(path: AppRoutes.language,       builder: (_, __) => const LanguagePage()),
      GoRoute(path: AppRoutes.security,       builder: (_, __) => const SecurityPage()),
      GoRoute(path: AppRoutes.currency,       builder: (_, __) => const CurrencyConversionPage()),
      GoRoute(path: AppRoutes.browserSettings, builder: (_, __) => const BrowserSettingsPage()),
      GoRoute(path: AppRoutes.addressBook,    builder: (_, __) => const AddressBookPage()),
      GoRoute(
        path: AppRoutes.networks,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return NetworkPage(popOnSelect: args?['popOnSelect'] as bool? ?? false);
        },
      ),

      GoRoute(path: AppRoutes.wallet,        builder: (_, __) => const WalletPage()),
      GoRoute(path: AppRoutes.addAccount,    builder: (_, __) => const AddAccount()),
      GoRoute(path: AppRoutes.receive,       builder: (_, __) => const ReceivePage()),
      GoRoute(path: AppRoutes.manageTokens,  builder: (_, __) => const ManageTokensPage()),
      GoRoute(path: AppRoutes.keystoreBackup, builder: (_, __) => const KeystoreBackup()),
      GoRoute(path: AppRoutes.revealSk,      builder: (_, __) => const RevealSecretKey()),
      GoRoute(path: AppRoutes.revealBip39,   builder: (_, __) => const RevealSecretPhrase()),
      GoRoute(path: AppRoutes.send,          builder: (_, __) => const SendTokenPage()),
      GoRoute(path: AppRoutes.zilStake,      builder: (_, __) => const ZilStakePage()),
      GoRoute(path: AppRoutes.addNetwork,    builder: (_, __) => const AddNetworkPage()),

      GoRoute(path: AppRoutes.netSetup,          builder: (_, __) => const SetupNetworkSettingsPage()),
      GoRoute(path: AppRoutes.passSetup,         builder: (_, __) => const PasswordSetupPage()),
      GoRoute(path: AppRoutes.newWalletOptions,  builder: (_, __) => const AddWalletOptionsPage()),
      GoRoute(path: AppRoutes.genOptions,        builder: (_, __) => const GenWalletOptionsPage()),
      GoRoute(path: AppRoutes.restoreOptions,    builder: (_, __) => const RestoreWalletOptionsPage()),
      GoRoute(path: AppRoutes.genSk,             builder: (_, __) => const SecretKeyGeneratorPage()),
      GoRoute(path: AppRoutes.genBip39,          builder: (_, __) => const SecretPhraseGeneratorPage()),
      GoRoute(path: AppRoutes.verifyBip39,       builder: (_, __) => const SecretPhraseVerifyPage()),
      GoRoute(path: AppRoutes.restoreSk,         builder: (_, __) => const SecretKeyRestorePage()),
      GoRoute(path: AppRoutes.restoreBip39,      builder: (_, __) => const RestoreSecretPhrasePage()),
      GoRoute(path: AppRoutes.keystoreFileRestore, builder: (_, __) => const RestoreKeystoreFilePage()),
      GoRoute(path: AppRoutes.ledgerConnect,    builder: (_, __) => const LedgerConnectPage()),
      GoRoute(path: AppRoutes.addLedgerAccount, builder: (_, __) => const AddLedgerAccountPage()),
    ],
  );
}
