import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/qrcode.dart';
import 'package:zilpay/state/app_state.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastProcessedUri;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    debugPrint('[DeepLinkService] Initializing...');

    try {
      final initialUri = await _appLinks.getInitialLink();
      debugPrint('[DeepLinkService] Initial link: $initialUri');

      if (initialUri != null) {
        _handleDeepLink(initialUri, navigatorKey);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('[DeepLinkService] Stream received URI: $uri');
          _handleDeepLink(uri, navigatorKey);
        },
        onError: (err) => debugPrint('[DeepLinkService] Error: $err'),
      );

      debugPrint('[DeepLinkService] Initialized successfully');
    } catch (e) {
      debugPrint('[DeepLinkService] Initialization error: $e');
    }
  }

  void _handleDeepLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    final uriString = uri.toString();

    if (_lastProcessedUri == uriString) {
      debugPrint('[DeepLinkService] Duplicate URI, skipping: $uriString');
      return;
    }

    _lastProcessedUri = uriString;

    debugPrint('=== Deep Link Received ===');
    debugPrint('Full URI: $uriString');
    debugPrint('Scheme: ${uri.scheme}');
    debugPrint('Host: ${uri.host}');
    debugPrint('Path: ${uri.path}');

    try {
      final parsed = parseCryptoUrl(uri.toString());
      debugPrint('Parsed data: $parsed');

      final context = navigatorKey.currentContext;
      debugPrint('Navigator context exists: ${context != null}');
      debugPrint('Parsed is empty: ${parsed.isEmpty}');
      debugPrint('Address exists: ${parsed['address'] != null}');

      if (context == null) {
        debugPrint('[DeepLinkService] No navigator context available');
        return;
      }

      if (parsed.isEmpty || parsed['address'] == null) {
        debugPrint('[DeepLinkService] Invalid parsed data, skipping navigation');
        return;
      }

      final chainName = parsed['chain'];
      if (chainName == null) {
        debugPrint('[DeepLinkService] No chain name in parsed data');
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);

      debugPrint('[DeepLinkService] Chain: $chainName');
      debugPrint('[DeepLinkService] Current wallet: ${appState.selectedWallet}');
      debugPrint('[DeepLinkService] Account exists: ${appState.account != null}');

      final walletIndex = _findWalletByChainName(appState, chainName);
      debugPrint('[DeepLinkService] Found wallet index: $walletIndex');

      if (walletIndex != -1) {
        appState.setSelectedWallet(walletIndex);
      }

      final deepLinkData = {
        'route': '/send',
        'wallet_index': walletIndex != -1 ? walletIndex : appState.selectedWallet,
        'arguments': {
          'recipient': parsed['address'],
          'amount': parsed['amount'],
          'token_address': parsed['token'],
        },
      };

      final currentChain = appState.chain;
      final canNavigate = appState.account != null &&
          currentChain != null &&
          _chainMatches(currentChain.shortName, chainName);

      debugPrint('[DeepLinkService] Current chain: ${currentChain?.shortName}');
      debugPrint('[DeepLinkService] Can navigate: $canNavigate');

      if (canNavigate) {
        debugPrint('[DeepLinkService] Navigating to /send directly');
        Navigator.of(context).pushNamed('/send', arguments: deepLinkData['arguments']);
      } else {
        debugPrint('[DeepLinkService] Storing for later and navigating to /login');
        appState.setPendingDeepLink(deepLinkData);
        Navigator.of(context).pushReplacementNamed('/login');
      }

      debugPrint('[DeepLinkService] Navigation triggered');
    } catch (e) {
      debugPrint('[DeepLinkService] Error handling deep link: $e');
    }

    debugPrint('=========================');
  }

  bool _chainMatches(String currentChain, String targetChain) {
    final current = currentChain.toLowerCase();
    final target = targetChain.toLowerCase();

    if (current == target) return true;

    final chainAliases = {
      'bnbchain': 'bnb',
      'bnb': 'bnbchain',
      'avalanche': 'avax',
      'avax': 'avalanche',
      'zilliqa': 'zil',
      'zil': 'zilliqa',
    };

    return chainAliases[current] == target || chainAliases[target] == current;
  }

  int _findWalletByChainName(AppState appState, String chainName) {
    for (int i = 0; i < appState.wallets.length; i++) {
      final wallet = appState.wallets[i];
      if (wallet.accounts.isEmpty) continue;

      final firstAccount = wallet.accounts[0];
      final chain = appState.getChain(firstAccount.chainHash);

      debugPrint('[DeepLinkService] Wallet $i: ${chain?.shortName}');

      if (chain != null && _chainMatches(chain.shortName, chainName)) {
        return i;
      }
    }

    return -1;
  }

  void dispose() {
    debugPrint('[DeepLinkService] Disposing...');
    _linkSubscription?.cancel();
  }
}
