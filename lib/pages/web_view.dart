import 'dart:io';
import 'dart:convert';
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

  Future<void> _applyEnhancedContentBlocking(AppState appState) async {
    final level = appState.state.browserSettings.contentBlocking;
    String jsCode = '';

    if (level >= 1) {
      jsCode = '''
        (function() {
          const adSelectors = [
            'iframe[src*="doubleclick.net"]',
            'iframe[src*="googleadservices"]',
            'div[id*="google_ads_"]',
            'div[class*="ad-container"]',
            'div[class*="advertisement"]',
            'div[class*="banner"]',
            'div[id*="banner-ad"]'
          ];
          adSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => el.style.display = 'none');
          });
          
          const blockAutoplay = function() {
            const videoElements = document.querySelectorAll('video');
            const audioElements = document.querySelectorAll('audio');
            
            for (const element of [...videoElements, ...audioElements]) {
              element.autoplay = false;
              element.pause();
              
              element.addEventListener('play', function(e) {
                if (!e.isTrusted) {
                  this.pause();
                }
              }, true);
            }
          };
          
          blockAutoplay();
          setInterval(blockAutoplay, 2000);
        })();
      ''';
    }

    if (level >= 2) {
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
            'script[src*="pixel"]',
            'div[class*="popup"]',
            'div[id*="popup"]',
            'div[class*="overlay"][class*="ad"]'
          ];
          
          blockSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => {
              el.style.display = 'none';
              if (el.parentNode) {
                el.parentNode.removeChild(el);
              }
            });
          });
          
          const blockAutoplay = function() {
            const mediaElements = [...document.querySelectorAll('video'), ...document.querySelectorAll('audio')];
            for (const element of mediaElements) {
              element.autoplay = false;
              element.pause();
              
              element.addEventListener('play', function(e) {
                if (!e.isTrusted) {
                  this.pause();
                }
              }, true);
            }
            
            const oldPlay = HTMLMediaElement.prototype.play;
            HTMLMediaElement.prototype.play = function() {
              if (document.userActivated) {
                return oldPlay.apply(this, arguments);
              }
              return Promise.reject('Autoplay blocked by ZilPay Browser');
            };
          };
          
          window.open = function() { return null; };
          window.showModalDialog = function() { return null; };
          
          window.ga = function() {};
          window.fbq = function() {};
          window._gaq = { push: function() {} };
          
          if (window.Notification) {
            window.Notification.requestPermission = function() {
              return Promise.resolve('denied');
            };
            Object.defineProperty(window.Notification, 'permission', {
              get: function() { return 'denied'; }
            });
          }
          
          blockAutoplay();
          setInterval(function() {
            blockSelectors.forEach(selector => {
              document.querySelectorAll(selector).forEach(el => {
                el.style.display = 'none';
                if (el.parentNode) {
                  el.parentNode.removeChild(el);
                }
              });
            });
            blockAutoplay();
          }, 2000);
          
          const observer = new MutationObserver(function(mutations) {
            let needsRecheck = false;
            for (const mutation of mutations) {
              if (mutation.addedNodes.length) {
                needsRecheck = true;
                break;
              }
            }
            
            if (needsRecheck) {
              blockSelectors.forEach(selector => {
                document.querySelectorAll(selector).forEach(el => {
                  el.style.display = 'none';
                  if (el.parentNode) {
                    el.parentNode.removeChild(el);
                  }
                });
              });
              blockAutoplay();
            }
          });
          
          observer.observe(document.body, { 
            childList: true, 
            subtree: true 
          });
        })();
      ''';
    }

    if (jsCode.isNotEmpty) {
      try {
        await _webViewController?.evaluateJavascript(source: jsCode);
      } catch (e) {
        debugPrint("$e");
      }
    }
  }

  Future<void> _disableAutoplay(AppState appState) async {
    if (!appState.state.browserSettings.allowAutoPlay) {
      try {
        await _webViewController?.evaluateJavascript(source: '''
          (function() {
            const disableAutoplay = function() {
              const videoElements = document.querySelectorAll('video');
              const audioElements = document.querySelectorAll('audio');
              
              for (const element of [...videoElements, ...audioElements]) {
                element.autoplay = false;
                element.pause();
                
                element.addEventListener('play', function(e) {
                  if (!e.isTrusted) {
                    this.pause();
                  }
                }, true);
              }
              
              if (!window.oldPlayDefined) {
                window.oldPlayDefined = true;
                const oldPlay = HTMLMediaElement.prototype.play;
                HTMLMediaElement.prototype.play = function() {
                  if (document.userActivated) {
                    return oldPlay.apply(this, arguments);
                  }
                  return Promise.reject('Autoplay blocked by browser settings');
                };
              }
            };
            
            const frames = document.querySelectorAll('iframe');
            frames.forEach(frame => {
              try {
                if (frame.contentDocument) {
                  const videos = frame.contentDocument.querySelectorAll('video');
                  videos.forEach(video => {
                    video.autoplay = false;
                    video.pause();
                  });
                }
              } catch (e) {}
            });
            
            disableAutoplay();
            setInterval(disableAutoplay, 2000);
          })();
        ''');
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

  void _applyPrivacySettings(
      AppState appState, InAppWebViewController controller) {
    if (!appState.state.browserSettings.cookiesEnabled) {
      _cookieManager?.deleteAllCookies();
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
                    javaScriptEnabled: true,
                    userAgent: _baseUserAgent +
                        (appState.state.browserSettings.doNotTrack
                            ? ' DNT:1'
                            : ' ZilPay/1.0'),
                    useHybridComposition: true,
                    supportZoom: true,
                    useOnLoadResource: true,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,
                    disableVerticalScroll: false,
                    disableHorizontalScroll: false,
                    transparentBackground: false,
                    javaScriptCanOpenWindowsAutomatically: false,
                    supportMultipleWindows: false,
                    cacheEnabled: appState.state.browserSettings.cacheEnabled,
                    clearCache: !appState.state.browserSettings.cacheEnabled,
                    mediaPlaybackRequiresUserGesture:
                        !appState.state.browserSettings.allowAutoPlay,
                    allowsInlineMediaPlayback:
                        appState.state.browserSettings.allowAutoPlay,
                    forceDark: appState.currentTheme.value == "Dark"
                        ? ForceDark.ON
                        : ForceDark.OFF,
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

                    _applyPrivacySettings(appState, controller);
                  },
                  onLoadStop: (controller, url) async {
                    await _initializeZilPayInjection(appState);

                    setState(() {
                      _isLoading = false;
                      _currentUrl = url.toString();
                    });

                    await _applyEnhancedContentBlocking(appState);

                    if (!appState.state.browserSettings.allowAutoPlay) {
                      await _disableAutoplay(appState);
                    }

                    if (_legacyHandler != null) {
                      _legacyHandler!.handleStartBlockWorker(appState);
                    }

                    if (appState.state.browserSettings.textScalingFactor !=
                        1.0) {
                      await _applyTextScalingFactor(appState);
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    if (_shouldIgnoreError(error)) return;

                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage = error.description;
                    });
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    final url =
                        navigationAction.request.url.toString().toLowerCase();

                    if (appState.state.browserSettings.contentBlocking > 0) {
                      final adDomains = [
                        'doubleclick.net',
                        'googleadservices',
                        'googlesyndication',
                        'adform.net',
                        'adnxs.com',
                        'ad.doubleclick.net',
                        'analytics',
                        'facebook.com/tr',
                      ];

                      for (final domain in adDomains) {
                        if (url.contains(domain)) {
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                    }

                    return NavigationActionPolicy.ALLOW;
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
