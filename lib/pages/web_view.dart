import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/web3/eip_1193.dart';
import 'package:zilpay/web3/message.dart';
import 'package:zilpay/web3/zilpay_legacy.dart';

class WebViewPage extends StatefulWidget {
  final String initialUrl;
  const WebViewPage({super.key, required this.initialUrl});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  ZilPayLegacyHandler? _legacyHandler;
  Web3EIP1193Handler? _eip1193Handler;
  CookieManager? _cookieManager;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentUrl = '';
  double _progress = 0;

  String get _baseUserAgent => Platform.isIOS
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1'
      : 'Mozilla/5.0 (Linux; Android 11; SM-G998U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cookieManager = CookieManager.instance();
    _currentUrl = widget.initialUrl;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _legacyHandler = null;
    _eip1193Handler = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _hasError &&
        _webViewController != null) {
      _refreshPage();
    }
  }

  void _setupJavaScriptHandlers() {
    if (_webViewController == null) return;

    _webViewController?.addJavaScriptHandler(
      handlerName: 'ZilPayLegacy',
      callback: (args) {
        try {
          final jsonData = jsonDecode(args[0]) as Map<String, dynamic>;
          final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
          _legacyHandler ??= ZilPayLegacyHandler(
            webViewController: _webViewController!,
            initialUrl: _currentUrl,
          );
          _legacyHandler!.handleLegacyZilPayMessage(zilPayMessage, context);
        } catch (e) {
          debugPrint("$e");
        }
        return null;
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'EIP1193Channel',
      callback: (args) {
        try {
          final jsonData = jsonDecode(args[0]) as Map<String, dynamic>;
          final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
          _eip1193Handler ??= Web3EIP1193Handler(
            webViewController: _webViewController!,
            initialUrl: _currentUrl,
          );
          _eip1193Handler!.handleWeb3EIP1193Message(zilPayMessage, context);
        } catch (e) {
          debugPrint("$e");
        }
        return null;
      },
    );
  }

  Future<void> _applyTextScalingFactor(AppState appState) async {
    try {
      await _webViewController?.evaluateJavascript(
          source:
              'document.documentElement.style.fontSize = \'${(appState.state.browserSettings.textScalingFactor * 100).toInt()}%\';');
    } catch (e) {
      debugPrint("$e");
    }
  }

  void _applyContentBlockingSettings(AppState appState) {
    final level = appState.state.browserSettings.contentBlocking;
    String jsCode = '';

    if (level == 1) {
      jsCode = '''
        (function() {
          const adSelectors = [
            'iframe[src*="doubleclick.net"]',
            'iframe[src*="googleadservices"]',
            'div[id*="google_ads_"]',
            'div[class*="ad-container"]',
            'div[class*="advertisement"]'
          ];
          adSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => el.style.display = 'none');
          });
        })();
      ''';
    } else if (level == 2) {
      jsCode = '''
        (function() {
          const blockSelectors = [
            'iframe[src*="doubleclick.net"]',
            'iframe[src*="googleadservices"]',
            'iframe[src*="facebook"]',
            'iframe[src*="twitter"]',
            'iframe[src*="instagram"]',
            'div[id*="google_ads_"]',
            'div[class*="ad-"]',
            'div[id*="ad-"]',
            'div[class*="social-"]',
            'div[class*="tracking"]',
            'script[src*="analytics"]',
            'script[src*="tracker"]',
            'script[src*="pixel"]'
          ];
          blockSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => el.style.display = 'none');
          });
          window.ga = function() {};
          window.fbq = function() {};
        })();
      ''';
    }

    if (jsCode.isNotEmpty) {
      try {
        _webViewController?.evaluateJavascript(source: jsCode);
      } catch (e) {
        debugPrint("$e");
      }
    }
  }

  Future<void> _initializeZilPayInjection(AppState appState) async {
    try {
      if (appState.chain?.slip44 == 313) {
        String eip1193 = await rootBundle.loadString('assets/evm_inject.js');
        String scilla =
            await rootBundle.loadString('assets/zilpay_legacy_inject.js');
        await _webViewController?.evaluateJavascript(
            source: '$scilla\n$eip1193');
        _legacyHandler ??= ZilPayLegacyHandler(
          webViewController: _webViewController!,
          initialUrl: _currentUrl,
        );
        await _legacyHandler!.sendData(appState);
      } else if (appState.chain?.slip44 == 60) {
        // String jsCode = await rootBundle.loadString('assets/evm_inject.js');
        await _webViewController?.injectJavascriptFileFromAsset(
          assetFilePath: 'assets/evm_inject.js',
        );
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  void _refreshPage() {
    _webViewController?.reload();
  }

  Map<String, String> _splitDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final parts = host.split('.');
      if (parts.length <= 2) {
        return {'subdomain': '', 'domain': host};
      }
      final subdomain = parts[0];
      final domain = parts.sublist(1).join('.');
      return {'subdomain': subdomain, 'domain': domain};
    } catch (e) {
      return {'subdomain': '', 'domain': url};
    }
  }

  bool _shouldIgnoreError(WebResourceError error) {
    final ignoredErrorContents = [
      'favicon.ico',
      'robots.txt',
      'analytics',
      'ads',
      'tracking',
      'facebook',
      'twitter',
      'google-analytics',
      'ga.js',
      'fbevents.js',
      'ERR_NAME_NOT_RESOLVED',
      'net::ERR_NAME_NOT_RESOLVED',
      'net::ERR_CLEARTEXT_NOT_PERMITTED',
      'CLEARTEXT_NOT_PERMITTED',
      'DNS_PROBE_FINISHED'
    ];

    for (final term in ignoredErrorContents) {
      if (error.description.toLowerCase().contains(term)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final domainParts =
        _splitDomain(_currentUrl.isEmpty ? widget.initialUrl : _currentUrl);

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
                    color: _currentUrl.startsWith('https://')
                        ? theme.primaryPurple
                        : theme.textSecondary,
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
                  if (appState.state.browserSettings.doNotTrack)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DNT',
                        style: TextStyle(
                          color: theme.primaryPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (appState.state.browserSettings.incognitoMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: theme.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Incognito',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
              },
            ),
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
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    javaScriptEnabled: true,
                    userAgent: _baseUserAgent +
                        (appState.state.browserSettings.doNotTrack
                            ? ' DNT:1'
                            : ' ZilPay/1.0'),
                    useHybridComposition: true,
                    supportZoom: true,
                    useOnLoadResource: true,
                    allowsInlineMediaPlayback: false,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,
                    disableVerticalScroll: false,
                    disableHorizontalScroll: false,
                    transparentBackground: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _setupJavaScriptHandlers();

                    if (!appState.state.browserSettings.cookiesEnabled) {
                      _cookieManager?.deleteAllCookies();
                    }
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                      _currentUrl = url.toString();
                    });

                    if (!appState.state.browserSettings.cacheEnabled) {
                      InAppWebViewController.clearAllCache();
                    }

                    if (appState.state.browserSettings.incognitoMode) {
                      InAppWebViewController.clearAllCache();
                      controller.clearHistory();
                      controller.clearFormData();
                      controller.closeAllMediaPresentations();

                      if (!appState.state.browserSettings.cookiesEnabled) {
                        _cookieManager?.deleteAllCookies();
                      }
                    }
                  },
                  onLoadStop: (controller, url) {
                    _initializeZilPayInjection(appState);

                    setState(() {
                      _isLoading = false;
                      _currentUrl = url.toString();
                    });

                    _applyContentBlockingSettings(appState);

                    if (_legacyHandler != null) {
                      _legacyHandler!.handleStartBlockWorker(appState);
                    }

                    if (appState.state.browserSettings.textScalingFactor !=
                        1.0) {
                      _applyTextScalingFactor(appState);
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });

                    if (progress > 30) {
                      // _initializeZilPayInjection(appState);
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    if (_shouldIgnoreError(error)) return;

                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage = error.description;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    // debugPrint("console message: ${consoleMessage.message}");
                  },
                ),
                if (_isLoading && _progress < 1.0)
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    color: theme.primaryPurple,
                  ),
              ],
            ),
    );
  }
}
