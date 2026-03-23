import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/state/app_state.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastProcessedUri;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri, navigatorKey);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          _handleDeepLink(uri, navigatorKey);
        },
        onError: (err) {},
      );
    } catch (e) {}
  }

  void _handleDeepLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    final uriString = uri.toString();

    if (_lastProcessedUri == uriString) {
      return;
    }

    _lastProcessedUri = uriString;

    try {
      final parsed = parseCryptoUrl(uri.toString());

      final context = navigatorKey.currentContext;

      if (context == null) {
        return;
      }

      if (parsed.isEmpty || parsed['address'] == null) {
        return;
      }

      final chainName = parsed['chain'];
      if (chainName == null) {
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);

      final walletIndex = _findWalletByChainName(appState, chainName);

      if (walletIndex != -1) {
        appState.setSelectedWallet(walletIndex);
      }

      final deepLinkData = {
        'route': '/send',
        'wallet_index':
            walletIndex != -1 ? walletIndex : appState.selectedWallet,
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

      if (canNavigate) {
        Navigator.of(context)
            .pushNamed('/send', arguments: deepLinkData['arguments']);
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {}
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
      final firstAccount =
          wallet.accounts[wallet.slip44]?[wallet.bip]?.elementAtOrNull(0);
      if (firstAccount == null) continue;
      final chain = appState.chain;

      if (chain != null && _chainMatches(chain.shortName, chainName)) {
        return i;
      }
    }

    return -1;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
