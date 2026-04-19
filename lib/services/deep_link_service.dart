import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/router.dart';
import 'package:bearby/state/app_state.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastProcessedUri;

  Future<void> initialize(GoRouter router, AppState appState) async {
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri, router, appState);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          _handleDeepLink(uri, router, appState);
        },
        onError: (err) {},
      );
    } catch (e) {
      //
    }
  }

  void _handleDeepLink(Uri uri, GoRouter router, AppState appState) {
    final uriString = uri.toString();

    if (_lastProcessedUri == uriString) {
      return;
    }

    _lastProcessedUri = uriString;

    try {
      final parsed = parseCryptoUrl(uri.toString());

      if (parsed.isEmpty || parsed['address'] == null) {
        return;
      }

      final chainName = parsed['chain'];
      if (chainName == null) {
        return;
      }

      final walletIndex = _findWalletByChainName(appState, chainName);

      if (walletIndex != -1) {
        appState.setSelectedWallet(walletIndex);
      }

      final sendArgs = {
        'recipient': parsed['address'],
        'amount': parsed['amount'],
        'token_address': parsed['token'],
      };

      final currentChain = appState.chain;
      final canNavigate = appState.account != null &&
          currentChain != null &&
          _chainMatches(currentChain.shortName, chainName);

      if (canNavigate) {
        router.push(AppRoutes.send, extra: sendArgs);
      } else {
        router.go(AppRoutes.login);
      }
    } catch (e) {
      //
    }
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
