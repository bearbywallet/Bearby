import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/config/zilliqa_legacy_messages.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class WebViewPage extends StatefulWidget {
  final String initialUrl;

  const WebViewPage({super.key, required this.initialUrl});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _webViewController;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppState appState = Provider.of<AppState>(context, listen: false);
    AppTheme theme = appState.currentTheme;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(theme.background)
      // ..setUserAgent('ZilPayBrowser/1.0')
      ..addJavaScriptChannel(
        'FlutterWebView',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final jsonData =
                jsonDecode(message.message) as Map<String, Object?>;
            final zilPayMessage = ZilPayMessage.fromJson(jsonData);
            _handleZilPayMessage(zilPayMessage);
          } catch (e) {
            debugPrint(
                'Failed to parse message: ${message.message}, error: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            String jsCode =
                await rootBundle.loadString('assets/zilpay_legacy_inject.js');
            await _webViewController.runJavaScript(jsCode);
          },
          onPageFinished: (String url) async {
            setState(() => _isLoading = false);
            String jsCode =
                await rootBundle.loadString('assets/zilpay_legacy_inject.js');
            await _webViewController.runJavaScript(jsCode);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${error.description}')));
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _refreshPage() => _webViewController.reload();

  void _sendResponse(String type, Map<String, Object?> payload) {
    final response = ZilPayMessage(type: type, payload: payload).toJson();
    final jsonString = jsonEncode(response);
    _webViewController.runJavaScript('window.postMessage($jsonString, "*")');
  }

  Future<Map<String, Object?>> _extractPageInfo() async {
    try {
      final descriptionResult =
          await _webViewController.runJavaScriptReturningResult(
              'document.querySelector("meta[name=\'description\']")?.content || ""');
      final primaryColorResult =
          await _webViewController.runJavaScriptReturningResult(
              'getComputedStyle(document.body).backgroundColor || "#FFFFFF"');

      final description = descriptionResult is String
          ? descriptionResult.replaceAll('"', '')
          : '';
      final primaryColor = primaryColorResult is String
          ? _parseColor(primaryColorResult)
          : '#FFFFFF';

      return {
        'description': description,
        'colors': {
          'primary': primaryColor,
          'secondary': null,
          'background': null,
          'text': null,
        },
      };
    } catch (e) {
      debugPrint('Failed to extract page info: $e');
      return {
        'description': '',
        'colors': {
          'primary': '#FFFFFF',
          'secondary': null,
          'background': null,
          'text': null
        },
      };
    }
  }

  String _parseColor(String color) {
    if (color.startsWith('rgb')) {
      final rgb = color
          .replaceAll(RegExp(r'[^0-9,]'), '')
          .split(',')
          .map(int.parse)
          .toList();
      return '#${rgb[0].toRadixString(16).padLeft(2, '0')}${rgb[1].toRadixString(16).padLeft(2, '0')}${rgb[2].toRadixString(16).padLeft(2, '0')}';
    }
    return color;
  }

  void _handleZilPayMessage(ZilPayMessage message) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentDomain = Uri.parse(widget.initialUrl).host;

    switch (message.type) {
      case ZilliqaLegacyMessages.getWalletData:
        await appState.syncConnections();
        final isConnected =
            appState.connections.any((conn) => conn.domain == currentDomain);
        _sendResponse(ZilliqaLegacyMessages.getWalletData, {
          'account': appState.wallet?.walletAddress ?? '',
          'network': appState.chain?.testnet ?? false ? 'testnet' : 'mainnet',
          'isConnect': isConnected,
          'isEnable': appState.wallet != null,
        });
        break;

      case ZilliqaLegacyMessages.contentProxyMethod:
        debugPrint('Content proxy method: ${message.payload}');
        break;

      case ZilliqaLegacyMessages.callToSignTx:
        debugPrint('Sign transaction request: ${message.payload}');
        break;

      case ZilliqaLegacyMessages.signMessage:
        debugPrint('Sign message request: ${message.payload}');
        break;

      case ZilliqaLegacyMessages.connectApp:
        final title = message.payload['title'] as String? ?? 'Unknown App';
        final uuid = message.payload['uuid'] as String? ?? '';
        final icon = message.payload['icon'] as String? ?? '';
        final domain = Uri.parse(widget.initialUrl).host;
        final pageInfo = await _extractPageInfo();

        if (!mounted) {
          return;
        }

        showAppConnectModal(
          context: context,
          title: title,
          uuid: uuid,
          iconUrl: icon,
          onDecision: (accepted, selectedIndices) async {
            final colorsMap = pageInfo['colors'] as Map<String, Object?>?;
            final walletIndexes = Uint64List.fromList(
                selectedIndices.map((index) => BigInt.from(index)).toList());

            ConnectionInfo connectionInfo = ConnectionInfo(
              domain: domain,
              walletIndexes: walletIndexes,
              favicon: icon,
              title: title,
              description: pageInfo['description'] as String?,
              colors: ColorsInfo(
                primary: colorsMap?['primary'] as String? ?? '#FFFFFF',
                secondary: colorsMap?['secondary'] as String?,
                background: colorsMap?['background'] as String?,
                text: colorsMap?['text'] as String?,
              ),
              lastConnected: BigInt.from(DateTime.now().millisecondsSinceEpoch),
              canReadAccounts: true,
              canRequestSignatures: true,
              canSuggestTokens: false,
              canSuggestTransactions: true,
            );

            if (accepted) {
              await createNewConnection(conn: connectionInfo);
              await appState.syncConnections();
            }

            _sendResponse(ZilliqaLegacyMessages.responseToDapp, {
              'uuid': uuid,
              'account': accepted && appState.account != null
                  ? {'address': appState.account!.addr}
                  : null,
            });
          },
        );
        break;

      case ZilliqaLegacyMessages.disconnectApp:
        debugPrint('Disconnect app request: ${message.payload}');
        _sendResponse(ZilliqaLegacyMessages.responseToDapp, {
          'uuid': message.payload['uuid'] as String? ?? '',
          'account': null,
        });
        break;

      default:
        debugPrint('Unhandled message type: ${message.type}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: theme.primaryPurple,
                    strokeWidth: 2,
                  ),
                )
              : HoverSvgIcon(
                  assetName: 'assets/icons/reload.svg',
                  width: 24,
                  height: 24,
                  onTap: _refreshPage,
                  color: theme.textPrimary,
                ),
          onPressed: _refreshPage,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            HoverSvgIcon(
              assetName: 'assets/icons/lock.svg',
              width: 16,
              height: 16,
              onTap: () {},
              color: theme.primaryPurple,
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.initialUrl,
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: HoverSvgIcon(
              assetName: 'assets/icons/close.svg',
              width: 24,
              height: 24,
              onTap: () => Navigator.pop(context),
              color: theme.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HoverSvgIcon(
                    assetName: 'assets/icons/warning.svg',
                    width: 100,
                    height: 100,
                    onTap: () {},
                    color: theme.textSecondary,
                  ),
                  SizedBox(height: 20),
                  Text('Failed to load',
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 16)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshPage,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryPurple),
                    child: Text('Try Again',
                        style: TextStyle(color: theme.background)),
                  ),
                ],
              ),
            )
          : WebViewWidget(controller: _webViewController),
    );
  }
}
