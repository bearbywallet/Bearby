import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bearby/components/hoverd_svg.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/glass_search_bar.dart';
import 'package:bearby/components/tile_button.dart';
import 'package:bearby/config/search_engines.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/browser_action_modal.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/web3/eip_1193.dart';
import 'package:bearby/web3/message.dart';
import 'package:bearby/web3/tron_web3.dart';
import 'package:bearby/web3/zilpay_legacy.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage>
    with WidgetsBindingObserver, StatusBarMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<GlassSearchBarState> _searchBarKey =
      GlobalKey<GlassSearchBarState>();

  InAppWebViewController? _webViewController;
  ZilPayLegacyHandler? _legacyHandler;
  Web3EIP1193Handler? _eip1193Handler;
  TronWeb3Handler? _tronHandler;
  CookieManager? _cookieManager;

  bool _isWebViewVisible = false;
  String _currentUrl = '';
  double _progress = 0;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  int? _lastKnownSlip44;
  AppState? _appState;
  String? _evmInjectScript;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cookieManager = CookieManager.instance();
    final appState = Provider.of<AppState>(context, listen: false);
    _appState = appState;
    appState.syncConnections();
    _lastKnownSlip44 = appState.chain?.slip44;
    appState.addListener(_handleChainChange);
    _loadEvmScript();
  }

  Future<void> _loadEvmScript() async {
    final src = await rootBundle.loadString('assets/evm_inject.js');
    if (mounted) setState(() => _evmInjectScript = src);
  }

  void _handleChainChange() {
    if (!mounted || _appState == null) return;
    final newSlip44 = _appState!.chain?.slip44;

    if (newSlip44 != _lastKnownSlip44 && _webViewController != null) {
      _lastKnownSlip44 = newSlip44;
      _setupJavaScriptHandlers();
      _initializeZilPayInjection(_appState!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState?.removeListener(_handleChainChange);
    _searchController.dispose();
    _legacyHandler?.dispose();
    _eip1193Handler?.dispose();
    _tronHandler?.dispose();
    _webViewController?.dispose();
    super.dispose();
  }

  void _showBrowserMenu() {
    final isConnected =
        _legacyHandler?.isConnected ?? _eip1193Handler?.isConnected ?? false;
    final appState = Provider.of<AppState>(context, listen: false);

    showBrowserActionModal(
      context: context,
      isConnected: isConnected,
      urlBarTop: appState.browserUrlBarTop,
      onUrlBarPositionChanged: (value) => appState.setBrowserUrlBarTop(value),
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
    final slip44 = appState.chain?.slip44;

    _legacyHandler?.dispose();
    _eip1193Handler?.dispose();
    _tronHandler?.dispose();
    _legacyHandler = null;
    _eip1193Handler = null;
    _tronHandler = null;

    if (slip44 == kEthereumSlip44 || slip44 == kZilliqaSlip44) {
      _eip1193Handler = Web3EIP1193Handler(
        webViewController: _webViewController!,
        appState: appState,
      );
    }

    if (slip44 == kZilliqaSlip44) {
      _legacyHandler = ZilPayLegacyHandler(
        webViewController: _webViewController!,
        appState: appState,
      );
    }

    if (slip44 == kTronSlip44) {
      _tronHandler = TronWeb3Handler(
        webViewController: _webViewController!,
        appState: appState,
      );
    }

    _webViewController?.addJavaScriptHandler(
      handlerName: 'ZilPayLegacy',
      callback: (args) {
        if (_legacyHandler == null || !mounted) return;
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
        if (_eip1193Handler == null || !mounted) return;
        try {
          final jsonData = jsonDecode(args[0]) as Map<String, dynamic>;
          final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
          _eip1193Handler?.handleWeb3EIP1193Message(zilPayMessage, context);
        } catch (e) {
          debugPrint("Error handling EIP1193Channel message: $e");
        }
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'TIP6963TRON',
      callback: (args) {
        if (_tronHandler == null || !mounted) return;
        try {
          final jsonData = jsonDecode(args.first) as Map<String, dynamic>;
          final zilPayMessage = ZilPayWeb3Message.fromJson(jsonData);
          _tronHandler?.handleWeb3TronMessage(zilPayMessage, context);
        } catch (e) {
          debugPrint("Error handling TIP6963TRON message: $e");
        }
      },
    );
  }

  Future<void> _initializeZilPayInjection(AppState appState) async {
    try {
      if (appState.chain?.slip44 == kEthereumSlip44 ||
          appState.chain?.slip44 == kZilliqaSlip44) {
        await _webViewController?.injectJavascriptFileFromAsset(
            assetFilePath: 'assets/evm_inject.js');
      }
      if (appState.chain?.slip44 == kZilliqaSlip44) {
        String scilla =
            await rootBundle.loadString('assets/zilpay_legacy_inject.js');
        await _webViewController?.evaluateJavascript(source: scilla);
        await _legacyHandler?.sendData(appState);
      }
      if (appState.chain?.slip44 == kTronSlip44) {
        await _webViewController?.injectJavascriptFileFromAsset(
            assetFilePath: 'assets/tron_inject.js');
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
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final urlBarTop = appState.browserUrlBarTop && _isWebViewVisible;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
      body: Stack(
        children: [
          SafeArea(
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
          if (_isWebViewVisible)
            Positioned(
              top: urlBarTop ? topPadding + 8 : null,
              bottom: !urlBarTop ? bottomPadding + 8 : null,
              left: 8,
              right: 8,
              child: _buildBrowserControls(theme),
            ),
          if (!_isWebViewVisible)
            Positioned(
              bottom: bottomPadding + 8,
              left: 8,
              right: 8,
              child: _buildSearchBar(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final slip44 = appState.chain?.slip44;
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
            initialUserScripts: UnmodifiableListView([
              if (_evmInjectScript != null &&
                  (slip44 == kEthereumSlip44 || slip44 == kZilliqaSlip44))
                UserScript(
                  source: _evmInjectScript!,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  contentWorld: ContentWorld.PAGE,
                ),
            ]),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              safeBrowsingEnabled: false,
              userAgent:
                  appState.state.browserSettings.doNotTrack ? 'DNT:1' : null,
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
            onConsoleMessage: (_, msg) {
              // print(msg);
            },
            onProgressChanged: (controller, progress) {
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
    final isDark = theme.value == "Dark";
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.4);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.3);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.2);
    final iconColor = isDark ? theme.textPrimary : Colors.white;
    final iconDisabledColor = isDark
        ? theme.textSecondary.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Row(
                children: [
                  HoverSvgIcon(
                    assetName: 'assets/icons/back.svg',
                    onTap:
                        _canGoBack ? () => _webViewController?.goBack() : () {},
                    color: _canGoBack ? iconColor : iconDisabledColor,
                    width: 24,
                    height: 24,
                  ),
                  HoverSvgIcon(
                    assetName: 'assets/icons/forward.svg',
                    onTap: _canGoForward
                        ? () => _webViewController?.goForward()
                        : () {},
                    color: _canGoForward ? iconColor : iconDisabledColor,
                    width: 24,
                    height: 24,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _handleSearch,
                      style: theme.bodyText1.copyWith(
                        color: isDark ? theme.textPrimary : Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                  ),
                  HoverSvgIcon(
                    assetName: 'assets/icons/dots.svg',
                    onTap: _showBrowserMenu,
                    color: iconColor,
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
                      try {
                        _tronHandler?.dispose();
                      } catch (e) {
                        //
                      }
                    },
                    color: iconColor,
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppTheme theme) {
    final appState = Provider.of<AppState>(context, listen: false);
    final searchEngineIndex = appState.state.browserSettings.searchEngineIndex;
    final searchEngine = baseSearchEngines[searchEngineIndex];
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: ListenableBuilder(
          listenable: _searchController,
          builder: (context, _) => GlassSearchBar(
            key: _searchBarKey,
            controller: _searchController,
            hint: l10n.browserPageSearchHint(searchEngine.name),
            onSubmitted: _handleSearch,
            keyboardType: TextInputType.url,
            rightIconPath: _searchController.text.isNotEmpty
                ? 'assets/icons/close.svg'
                : null,
            onRightIconTap: () => _searchController.clear(),
          ),
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
          style: theme.bodyLarge.copyWith(color: theme.textSecondary),
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
