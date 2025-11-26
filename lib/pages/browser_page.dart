import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/config/search_engines.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/modals/browser_action_modal.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/web3/eip_1193.dart';
import 'package:zilpay/web3/message.dart';
import 'package:zilpay/web3/zilpay_legacy.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage>
    with WidgetsBindingObserver, StatusBarMixin {
  final TextEditingController _searchController = TextEditingController();

  InAppWebViewController? _webViewController;
  ZilPayLegacyHandler? _legacyHandler;
  Web3EIP1193Handler? _eip1193Handler;
  CookieManager? _cookieManager;

  bool _isWebViewVisible = false;
  String _currentUrl = '';
  double _progress = 0;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;

  String get _baseUserAgent => Platform.isIOS
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1'
      : 'Mozilla/5.0 (Linux; Android 11; SM-G998U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cookieManager = CookieManager.instance();
    final appState = Provider.of<AppState>(context, listen: false);
    appState.syncConnections();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _legacyHandler?.dispose();
    _webViewController?.dispose();
    super.dispose();
  }

  void _showBrowserMenu() {
    final isConnected =
        _legacyHandler?.isConnected ?? _eip1193Handler?.isConnected ?? false;

    showBrowserActionModal(
      context: context,
      isConnected: isConnected,
      onRefresh: () => _webViewController?.reload(),
      onCopyLink: () async {
        final url = await _webViewController?.getUrl();
        if (url != null) {
          await Clipboard.setData(ClipboardData(text: url.toString()));
        }
      },
      onShare: () async {
        final url = await _webViewController?.getUrl();
        if (url != null) {
          SharePlus.instance.share(
            ShareParams(
              text: _currentUrl,
            ),
          );
        }
      },
    );
  }

  void _handleSearch(String value) {
    if (value.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final browserSettings = appState.state.browserSettings;
    final searchEngineIndex = browserSettings.searchEngineIndex;
    final searchEngine = baseSearchEngines[searchEngineIndex];
    String query = value.trim();
    String url;
    final uri = Uri.tryParse(query);

    if (uri != null) {
      if (uri.hasScheme && uri.hasAuthority) {
        url = query;
      } else if (uri.hasAuthority && uri.port != 0) {
        url = 'http://$query';
      } else if (isDomainName(query)) {
        url = 'https://$query';
      } else {
        url = '${searchEngine.url}${Uri.encodeQueryComponent(query)}';
      }
    } else {
      if (isDomainName(query)) {
        url = 'https://$query';
      } else {
        url = '${searchEngine.url}${Uri.encodeQueryComponent(query)}';
      }
    }
    _openWebView(url);
  }

  void _openWebView(String url) {
    setState(() {
      _currentUrl = url;
      _searchController.text = url;
      _isWebViewVisible = true;
    });
  }

  bool isDomainName(String input) {
    final domainPart = input.split(':')[0];
    final domainRegex = RegExp(
        r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$');
    return domainRegex.hasMatch(domainPart);
  }

  void _setupJavaScriptHandlers() {
    if (_webViewController == null) return;
    final appState = Provider.of<AppState>(context, listen: false);

    _legacyHandler = ZilPayLegacyHandler(
      webViewController: _webViewController!,
      appState: appState,
    );
    _eip1193Handler = Web3EIP1193Handler(
      webViewController: _webViewController!,
      initialUrl: _currentUrl,
      appState: appState,
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'ZilPayLegacy',
      callback: (args) {
        if (!mounted) return;
        try {
          final jsonData = jsonDecode(args[0]) as Map<String, dynamic>;
          final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
          _legacyHandler?.handleLegacyZilPayMessage(zilPayMessage, context);
        } catch (e) {
          debugPrint("Error handling ZilPayLegacy message: $e");
        }
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'EIP1193Channel',
      callback: (args) {
        if (!mounted) return;
        try {
          final jsonData = jsonDecode(args[0]) as Map<String, dynamic>;
          final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
          _eip1193Handler?.handleWeb3EIP1193Message(zilPayMessage, context);
        } catch (e) {
          debugPrint("Error handling EIP1193Channel message: $e");
        }
      },
    );
  }

  Future<void> _initializeZilPayInjection(AppState appState) async {
    try {
      if (appState.chain?.slip44 == 60 || appState.chain?.slip44 == 313) {
        await _webViewController?.injectJavascriptFileFromAsset(
            assetFilePath: 'assets/evm_inject.js');
      }
      if (appState.chain?.slip44 == 313) {
        String scilla =
            await rootBundle.loadString('assets/zilpay_legacy_inject.js');
        await _webViewController?.evaluateJavascript(source: scilla);
        await _legacyHandler?.sendData(appState);
      }
    } catch (e) {
      debugPrint("Injection Error: $e");
    }
  }

  void _applyPrivacySettings(
      AppState appState, InAppWebViewController controller) {
    if (!appState.state.browserSettings.cookiesEnabled) {
      _cookieManager?.deleteAllCookies();
    }
    if (appState.state.browserSettings.incognitoMode) {
      InAppWebViewController.clearAllCache();
      controller.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildConnectedTab(
                    appState.connections,
                    theme,
                    EdgeInsets.symmetric(horizontal: adaptivePadding),
                  ),
                  if (_isWebViewVisible) _buildWebView(),
                ],
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(adaptivePadding, 8, adaptivePadding, 0),
              child: _isWebViewVisible
                  ? _buildBrowserControls(theme)
                  : _buildSearchBar(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    return Column(
      children: [
        if (_isLoading && _progress < 1.0)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.transparent,
            color: theme.primaryPurple,
            minHeight: 2,
          ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              safeBrowsingEnabled: false,
              userAgent: _baseUserAgent +
                  (appState.state.browserSettings.doNotTrack
                      ? ' DNT:1'
                      : ' ZilPay/1.0'),
              useHybridComposition: true,
              supportZoom: true,
              useOnLoadResource: true,
              verticalScrollBarEnabled: false,
              horizontalScrollBarEnabled: false,
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
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
                _currentUrl = url.toString();
                _searchController.text = url.toString();
              });
              _applyPrivacySettings(appState, controller);
            },
            onLoadStop: (controller, url) async {
              await _initializeZilPayInjection(appState);

              final canGoBack = await controller.canGoBack();
              final canGoForward = await controller.canGoForward();
              setState(() {
                _isLoading = false;
                _currentUrl = url.toString();
                _searchController.text = url.toString();
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });

              _legacyHandler?.handleStartBlockWorker(appState);
            },
            onProgressChanged: (controller, progress) async {
              if (progress > 20) {
                await _initializeZilPayInjection(appState);
              }

              setState(() => _progress = progress / 100);
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) async {
              final canGoBack = await controller.canGoBack();
              final canGoForward = await controller.canGoForward();
              setState(() {
                _currentUrl = url.toString();
                _searchController.text = url.toString();
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrowserControls(AppTheme theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          HoverSvgIcon(
            assetName: 'assets/icons/back.svg',
            onTap: _canGoBack ? () => _webViewController?.goBack() : () {},
            color: _canGoBack
                ? theme.textPrimary
                : theme.textSecondary.withValues(alpha: 0.5),
            width: 24,
            height: 24,
          ),
          HoverSvgIcon(
            assetName: 'assets/icons/forward.svg',
            onTap:
                _canGoForward ? () => _webViewController?.goForward() : () {},
            color: _canGoForward
                ? theme.textPrimary
                : theme.textSecondary.withValues(alpha: 0.5),
            width: 24,
            height: 24,
          ),
          Expanded(
            child: SmartInput(
              controller: _searchController,
              onSubmitted: _handleSearch,
              borderColor: Colors.transparent,
              focusedBorderColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              height: 48,
              fontSize: 14,
            ),
          ),
          HoverSvgIcon(
            assetName: 'assets/icons/dots.svg',
            onTap: _showBrowserMenu,
            color: theme.textPrimary,
            width: 24,
            height: 24,
          ),
          HoverSvgIcon(
            assetName: 'assets/icons/close.svg',
            onTap: () async {
              setState(() {
                _isWebViewVisible = false;
                _searchController.text = "";
                _searchController.clear();
              });

              try {
                _legacyHandler?.dispose();
              } catch (e) {
                //
              }

              try {
                _eip1193Handler?.dispose();
              } catch (e) {
                //
              }
            },
            color: theme.textPrimary,
            width: 24,
            height: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppTheme theme) {
    final appState = Provider.of<AppState>(context);
    final searchEngineIndex = appState.state.browserSettings.searchEngineIndex;
    final searchEngine = baseSearchEngines[searchEngineIndex];
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SmartInput(
          controller: _searchController,
          hint: l10n.browserPageSearchHint(searchEngine.name),
          leftIconPath: 'assets/icons/search.svg',
          onSubmitted: _handleSearch,
          borderColor: theme.textPrimary,
          focusedBorderColor: theme.primaryPurple,
          height: 48,
          fontSize: 16,
          autofocus: false,
          keyboardType: TextInputType.url,
        ),
      ),
    );
  }

  Widget _buildConnectedTab(
    List<ConnectionInfo> connections,
    AppTheme theme,
    EdgeInsets padding,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (connections.isEmpty) {
      return Center(
        child: Text(
          l10n.browserPageNoConnectedApps,
          style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
      );
    }

    return SingleChildScrollView(
      padding: padding.copyWith(top: 32, bottom: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: connections.map((connection) {
              final url = 'https://${connection.domain}';
              return _buildConnectedTile(
                connection.title,
                connection.favicon,
                url,
                theme,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedTile(
    String label,
    String? iconUrl,
    String url,
    AppTheme theme,
  ) {
    return TileButton(
      title: label,
      icon: AsyncImage(
        url: iconUrl,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        errorWidget: HoverSvgIcon(
          assetName: 'assets/icons/warning.svg',
          width: 30,
          height: 30,
          onTap: () {},
          color: theme.textPrimary,
        ),
      ),
      onPressed: () => _openWebView(url),
      backgroundColor: theme.cardBackground,
      textColor: theme.primaryPurple,
    );
  }
}
