import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'package:bearby/config/whitebird.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/services/whitebird_session.dart';
import 'package:bearby/state/app_state.dart';

/// Sell handoff: show the wallet transfer confirm over the SDK's deposit
/// screen; return `true` once the transaction is signed and broadcast.
typedef WhiteBirdDepositHandler = Future<bool> Function(WhiteBirdDeposit deposit);

/// Deposit details from the SDK `onOrderCreated` callback.
@immutable
class WhiteBirdDeposit {
  const WhiteBirdDeposit({required this.orderId, required this.depositAddress});

  final String orderId;
  final String depositAddress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhiteBirdDeposit &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          depositAddress == other.depositAddress;

  @override
  int get hashCode => Object.hash(orderId, depositAddress);

  @override
  String toString() =>
      'WhiteBirdDeposit(orderId: $orderId, depositAddress: $depositAddress)';
}

/// WhiteBird SDK WebView host.
///
/// - `sessionId == null` → auth-only (login / signup / KYC); pops `true` once
///   the SDK returns tokens via `onUserData`.
/// - `sessionId != null` → exchange flow with a locked pair/amount; sells pass
///   [onDepositReady] to intercept the deposit for the wallet confirm modal,
///   buys complete fully inside the SDK (`onOrderCompleted`).
class WhiteBirdSdkPage extends StatefulWidget {
  const WhiteBirdSdkPage({
    super.key,
    required this.isTestnet,
    required this.externalClientId,
    this.accessToken,
    this.refreshToken,
    this.sessionId,
    this.currencyFrom,
    this.currencyTo,
    this.currencyAmount,
    this.cryptoWallet,
    this.onDepositReady,
  });

  final bool isTestnet;

  /// Links the WhiteBird user with this install (`ensureExternalClientId`).
  final String externalClientId;

  /// Stored WhiteBird JWTs — lets the SDK skip its login screen.
  final String? accessToken;
  final String? refreshToken;

  final String? sessionId;
  final String? currencyFrom;
  final String? currencyTo;
  final String? currencyAmount;
  final String? cryptoWallet;
  final WhiteBirdDepositHandler? onDepositReady;

  bool get authOnly => sessionId == null;

  @override
  State<WhiteBirdSdkPage> createState() => _WhiteBirdSdkPageState();
}

class _WhiteBirdSdkPageState extends State<WhiteBirdSdkPage> with StatusBarMixin {
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _handledOrder = false;
  bool _popped = false;

  @override
  void dispose() {
    _cleanupSdk();
    super.dispose();
  }

  String _buildHostHtml() {
    // jsonEncode gives safely quoted JS string/null literals.
    final params = <String, String>{
      'merchantId': jsonEncode(WhiteBirdConfig.merchantId),
      'merchantPass': jsonEncode(WhiteBirdConfig.merchantPass),
    };
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>html,body{margin:0;padding:0;height:100%;background:transparent}</style>
</head>
<body>
  <div id="wb" style="position:fixed;inset:0"></div>
  <script src="${WhiteBirdConfig.sdkScriptUrlTestnet}"></script>
  <script>
    function send(name, payload) {
      window.flutter_inappwebview.callHandler(name, payload || {});
    }
    wbExchangeSdk.setup({
      el: document.getElementById('wb'),
      mode: wbExchangeSdk.mode.LoginMode,
      merchantId: ${params['merchantId']},
      merchantPass: ${params['merchantPass']},
      ${_setupExtras()}
      showBackButtonOnHomePage: true,
      onExit: function() { send('wbExit'); },
      onUserData: function(p) { send('wbUserData', p); },
      onOrderCreated: function(p) { send('wbOrderCreated', p); },
      onOrderCompleted: function(p) { send('wbOrderCompleted', p); },
    });
  </script>
</body>
</html>
''';
  }

  /// Session/token lines of the `wbExchangeSdk.setup` object.
  String _setupExtras() {
    final buffer = StringBuffer();
    void line(String key, Object? value) {
      if (value == null) return;
      buffer.writeln('$key: ${jsonEncode(value)},');
    }

    line('externalClientId', widget.externalClientId);
    line('accessToken', widget.accessToken);
    line('refreshToken', widget.refreshToken);
    if (!widget.authOnly) {
      line('sessionId', widget.sessionId);
      line('currencyFrom', widget.currencyFrom);
      line('currencyTo', widget.currencyTo);
      final amount = double.tryParse(widget.currencyAmount ?? '');
      if (amount != null) buffer.writeln('currencyAmount: $amount,');
      line('cryptoWallet', widget.cryptoWallet);
      buffer.writeln('disableCurrencyFrom: true,');
      buffer.writeln('disableCurrencyTo: true,');
      buffer.writeln('disableAmount: true,');
    }
    return buffer.toString();
  }

  Map<String, Object?> _payload(List<dynamic> args) {
    final first = args.firstOrNull;
    if (first is Map) {
      return first.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static String? _stringField(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  void _pop(bool result) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _cleanupSdk() async {
    try {
      await _controller?.evaluateJavascript(
        source: 'try{wbExchangeSdk.cleanup();}catch(e){}',
      );
    } catch (_) {}
  }

  Future<void> _onUserData(List<dynamic> args) async {
    final map = _payload(args);
    final access = _stringField(map, const ['accessToken']);
    final refresh = _stringField(map, const ['refreshToken']);
    if (access == null || refresh == null) {
      debugPrint('[WhiteBird] onUserData missing tokens keys=${map.keys}');
      return;
    }
    final session = WhiteBirdSession(context.read<AppState>().storage);
    await session.ensureLoaded();
    await session.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      email: _stringField(map, const ['email']),
    );
    final clientId = _stringField(map, const ['clientId', 'id']);
    if (clientId != null) await session.saveClientId(clientId);
    debugPrint('[WhiteBird] tokens saved (authOnly=${widget.authOnly})');
    if (widget.authOnly) {
      await _cleanupSdk();
      _pop(true);
    }
  }

  Future<void> _onOrderCreated(List<dynamic> args) async {
    final map = _payload(args);
    final deposit = _stringField(
        map, const ['internalCryptoAddress', 'depositCryptoAddress']);
    final orderId = _stringField(map, const ['orderId', 'id']);
    debugPrint('[WhiteBird] order created id=$orderId deposit=$deposit');

    final handler = widget.onDepositReady;
    if (handler == null || deposit == null || _handledOrder || _popped) return;
    _handledOrder = true;

    final confirmed = await handler(
      WhiteBirdDeposit(orderId: orderId ?? '', depositAddress: deposit),
    );
    debugPrint('[WhiteBird] deposit transfer confirmed=$confirmed');
    if (confirmed) {
      await _cleanupSdk();
      _pop(true);
    } else {
      // User dismissed the confirm modal — the SDK deposit screen stays up so
      // they can still pay manually or exit; the order remains PROCESSING.
      _handledOrder = false;
    }
  }

  Future<void> _onOrderCompleted(List<dynamic> args) async {
    final map = _payload(args);
    debugPrint('[WhiteBird] order completed '
        'id=${_stringField(map, const ['orderId'])} '
        'status=${_stringField(map, const ['status'])}');
    // Buy flow finishes here; sells already popped after the transfer confirm.
    if (widget.onDepositReady == null && !widget.authOnly) {
      await _cleanupSdk();
      _pop(true);
    }
  }

  void _registerHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'wbExit',
      callback: (args) => _pop(false),
    );
    controller.addJavaScriptHandler(
      handlerName: 'wbUserData',
      callback: (args) => _onUserData(args),
    );
    controller.addJavaScriptHandler(
      handlerName: 'wbOrderCreated',
      callback: (args) => _onOrderCreated(args),
    );
    controller.addJavaScriptHandler(
      handlerName: 'wbOrderCompleted',
      callback: (args) => _onOrderCompleted(args),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().currentTheme;
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.background,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textPrimary),
          onPressed: () => _pop(false),
        ),
        title: Text(
          'WhiteBird',
          style: theme.titleMedium.copyWith(color: theme.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialData: InAppWebViewInitialData(
                data: _buildHostHtml(),
                baseUrl: WebUri('https://bearby.io'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useHybridComposition: true,
                transparentBackground: true,
                // Card payment providers open their pages via window.open.
                javaScriptCanOpenWindowsAutomatically: true,
                supportMultipleWindows: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                _registerHandlers(controller);
              },
              onCreateWindow: (controller, action) async {
                final url = action.request.url;
                if (url != null) {
                  await controller.loadUrl(urlRequest: URLRequest(url: url));
                }
                return false;
              },
              onLoadStop: (controller, url) {
                if (mounted) setState(() => _loading = false);
              },
              onReceivedError: (controller, request, error) {
                debugPrint('[WhiteBird] webview error ${error.description}');
              },
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
