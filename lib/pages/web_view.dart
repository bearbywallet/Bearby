import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/web3/eip_1193.dart';
import 'package:zilpay/web3/message.dart';
import 'package:zilpay/web3/zilpay_legacy.dart';
import 'dart:convert';

class WebViewPage extends StatefulWidget {
  final String initialUrl;

  const WebViewPage({super.key, required this.initialUrl});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _webViewController;
  late ZilPayLegacyHandler _legacyHandler;
  late Web3EIP1193Handler _eip1193Handler;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    AppTheme theme = appState.currentTheme;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(theme.background)
      ..addJavaScriptChannel(
        'ZilPayLegacy',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final jsonData =
                jsonDecode(message.message) as Map<String, dynamic>;
            final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
            _legacyHandler.handleLegacyZilPayMessage(zilPayMessage, context);
          } catch (e) {
            debugPrint(
                'Failed to parse message: ${message.message}, error: $e');
          }
        },
      )
      ..addJavaScriptChannel(
        'EIP1193Channel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final jsonData =
                jsonDecode(message.message) as Map<String, dynamic>;
            final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
            _eip1193Handler.handleWeb3EIP1193Message(zilPayMessage, context);
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
            // await _webViewController.clearCache();
            // await _webViewController.clearLocalStorage();
          },
          onProgress: (_) async {
            await _initializeZilPayInjection(appState);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            _legacyHandler.handleStartBlockWorker(appState);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    _legacyHandler = ZilPayLegacyHandler(
      webViewController: _webViewController,
      initialUrl: widget.initialUrl,
    );
    _eip1193Handler = Web3EIP1193Handler(
      webViewController: _webViewController,
      initialUrl: widget.initialUrl,
    );
  }

  Future<void> _initializeZilPayInjection(AppState appState) async {
    if (appState.chain?.slip44 == 313) {
      String eip1193 = await rootBundle.loadString('assets/evm_inject.js');
      String scilla =
          await rootBundle.loadString('assets/zilpay_legacy_inject.js');
      await _webViewController.runJavaScript('$scilla\n$eip1193');
      await _legacyHandler.sendData(appState);
    } else if (appState.chain?.slip44 == 60) {
      String jsCode = await rootBundle.loadString('assets/evm_inject.js');
      await _webViewController.runJavaScript(jsCode);
    }
  }

  void _refreshPage() {
    _webViewController.reload();
  }

  Map<String, String> _splitDomain(String url) {
    final uri = Uri.parse(url);
    final host = uri.host;
    final parts = host.split('.');

    if (parts.length <= 2) {
      return {'subdomain': '', 'domain': host};
    }

    final subdomain = parts[0];
    final domain = parts.sublist(1).join('.');
    return {'subdomain': subdomain, 'domain': domain};
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final domainParts = _splitDomain(widget.initialUrl);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
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
          title: Stack(
            children: [
              Row(
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
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          if (domainParts['subdomain']!.isNotEmpty)
                            TextSpan(
                              text: '${domainParts['subdomain']}.',
                              style: TextStyle(
                                color:
                                    theme.textSecondary.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          TextSpan(
                            text: domainParts['domain'],
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
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
                onPressed: () {
                  stopBlockWorker();
                  Navigator.pop(context);
                }),
          ],
        ),
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
                  const SizedBox(height: 20),
                  Text(
                    'Failed to load',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryPurple,
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(color: theme.background),
                    ),
                  ),
                ],
              ),
            )
          : WebViewWidget(controller: _webViewController),
    );
  }
}
