import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/router.dart';
import 'package:bearby/services/walletconnect_service.dart';
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
      // WalletConnect pairing (wc:… or custom scheme → wc:…)
      final raw = uriString;
      if (WalletConnectService.isWalletConnectUri(raw) ||
          uri.scheme == 'wc' ||
          (uri.queryParameters.containsKey('uri') &&
              WalletConnectService.isWalletConnectUri(
                  uri.queryParameters['uri']!))) {
        final wcUri = uri.queryParameters['uri'] ??
            (raw.startsWith('wc:') ? raw : uri.toString());
        WalletConnectService.instance.pair(wcUri).catchError((Object e) {
          debugPrint('wc deep link pair: $e');
        });
        return;
      }

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
          chainMatches(currentChain, chainName);

      if (canNavigate) {
        router.push(AppRoutes.send, extra: sendArgs);
      } else {
        router.go(AppRoutes.login);
      }
    } catch (e) {
      //
    }
  }

  int _findWalletByChainName(AppState appState, String chainName) {
    for (int i = 0; i < appState.wallets.length; i++) {
      final chain = appState.chain;

      if (chain != null && chainMatches(chain, chainName)) {
        return i;
      }
    }

    return -1;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
