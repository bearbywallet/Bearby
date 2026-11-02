import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_plus/webview_plus.dart';
// ignore: implementation_imports
import 'package:webview_plus/src/webview_plus_user_script.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bearby/components/browser_control_bar.dart';
import 'package:bearby/components/hover_icon.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/glass_search_bar.dart';
import 'package:bearby/components/tile_button.dart';
import 'package:bearby/config/search_engines.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/web3/eip_1193.dart';
import 'package:bearby/web3/message.dart';
import 'package:bearby/web3/tron_web3.dart';
import 'package:bearby/web3/web3_response.dart';
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

  WebviewPlusController? _webViewController;
  ZilPayLegacyHandler? _legacyHandler;
  Web3EIP1193Handler? _eip1193Handler;
  TronWeb3Handler? _tronHandler;

  bool _isWebViewVisible = false;
  String _currentUrl = '';
  double _progress = 0;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  int? _lastKnownSlip44;
  AppState? _appState;
  String? _evmInjectScript;
  String? _tronInjectScript;
  String? _zilpayLegacyInjectScript;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final appState = Provider.of<AppState>(context, listen: false);
    _appState = appState;
    appState.syncConnections();
    _lastKnownSlip44 = appState.chain?.slip44;
    appState.addListener(_handleChainChange);
    _loadInjectScripts();
  }

  Future<void> _loadInjectScripts() async {
    try {
      final evm = await rootBundle.loadString('assets/.evm_inject.js');
      final tron = await rootBundle.loadString('assets/.tron_inject.js');
      final scilla =
          await rootBundle.loadString('assets/.zilpay_legacy_inject.js');
      if (mounted) {
        setState(() {
          _evmInjectScript = evm;
          _tronInjectScript = tron;
          _zilpayLegacyInjectScript = scilla;
        });
      }
    } catch (e) {
      debugPrint('_loadInjectScripts: $e');
    }
  }

  void _handleChainChange() {
    if (!mounted || _appState == null) return;
    final newSlip44 = _appState!.chain?.slip44;

    if (newSlip44 != _lastKnownSlip44 && _webViewController != null) {
      final prevSlip44 = _lastKnownSlip44;
      _lastKnownSlip44 = newSlip44;
      final bothUseEip1193 = (prevSlip44 == kEthereumSlip44 ||
              prevSlip44 == kSolanaSlip44) &&
          (newSlip44 == kEthereumSlip44 || newSlip44 == kSolanaSlip44);
      if (!bothUseEip1193) {
        _setupJavaScriptHandlers();
        _initializeZilPayInjection(_appState!);
      }
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
    super.dispose();
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
    final wasVisible = _isWebViewVisible;
    setState(() {
      _currentUrl = url;
      _searchController.text = url;
      _isWebViewVisible = true;
    });
    if (wasVisible && _webViewController != null) {
      _webViewController!.loadUrl(url);
    }
  }

  bool isDomainName(String input) {
    if (input.contains(' ')) return false;
    final hostPart = input
        .split('/')
        .first
        .split('?')
        .first
        .split('#')
        .first
        .split(':')
        .first;
    final domainRegex = RegExp(
        r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$');
    return domainRegex.hasMatch(hostPart);
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

    if (slip44 == kEthereumSlip44 ||
        slip44 == kZilliqaSlip44 ||
        slip44 == kSolanaSlip44) {
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
          appState.chain?.slip44 == kZilliqaSlip44 ||
          appState.chain?.slip44 == kSolanaSlip44) {
        final evm = _evmInjectScript ??
            await rootBundle.loadString('assets/.evm_inject.js');
        await _webViewController?.evaluateJavascript(evm);
      }
      if (appState.chain?.slip44 == kZilliqaSlip44) {
        final scilla = _zilpayLegacyInjectScript ??
            await rootBundle.loadString('assets/.zilpay_legacy_inject.js');
        await _webViewController?.evaluateJavascript(scilla);
        await _legacyHandler?.sendData(appState);
      }
      if (appState.chain?.slip44 == kTronSlip44) {
        final tron = _tronInjectScript ??
            await rootBundle.loadString('assets/.tron_inject.js');
        await _webViewController?.evaluateJavascript(tron);
      }
    } catch (e) {
      debugPrint("Injection Error: $e");
    }
  }

  void _applyPrivacySettings(
      AppState appState, WebviewPlusController controller) {
    if (!appState.state.browserSettings.cookiesEnabled) {
      WebviewCacheManager.clearCookies();
    }
    if (appState.state.browserSettings.incognitoMode) {
      WebviewCacheManager.clearCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
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
          if (_isWebViewVisible) _buildBrowserControls(appState),
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
          child: WebviewWidget(
            initialUrl: _currentUrl,
            initialSettings: WebviewSettings(
              javaScriptEnabled: true,
              safeBrowsingEnabled: false,
              androidPlatformViewType:
                  AndroidPlatformViewType.hybridComposition,
              supportZoom: true,
              hideNativeScrollbars: true,
              transparentBackground: false,
              javaScriptCanOpenWindowsAutomatically: false,
              cacheEnabled: appState.state.browserSettings.cacheEnabled,
              incognito: appState.state.browserSettings.incognitoMode,
              thirdPartyCookiesEnabled:
                  appState.state.browserSettings.cookiesEnabled,
              mediaPlaybackRequiresUserGesture:
                  !appState.state.browserSettings.allowAutoPlay,
              allowsInlineMediaPlayback:
                  appState.state.browserSettings.allowAutoPlay,
              forceDarkMode: appState.currentTheme.value == "Dark",
              initialUserScripts: [
                if (_evmInjectScript != null &&
                    (slip44 == kEthereumSlip44 ||
                        slip44 == kZilliqaSlip44 ||
                        slip44 == kSolanaSlip44))
                  UserScript(
                    source: _evmInjectScript!,
                    injectionTime: UserScriptInjectionTime.atDocumentStart,
                  ),
                if (_zilpayLegacyInjectScript != null &&
                    slip44 == kZilliqaSlip44)
                  UserScript(
                    source: _zilpayLegacyInjectScript!,
                    injectionTime: UserScriptInjectionTime.atDocumentStart,
                  ),
                if (_tronInjectScript != null && slip44 == kTronSlip44)
                  UserScript(
                    source: _tronInjectScript!,
                    injectionTime: UserScriptInjectionTime.atDocumentStart,
                  ),
              ],
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
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _currentUrl = url.toString();
                _searchController.text = url.toString();
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });

              _legacyHandler?.handleStartBlockWorker(appState);
            },
            onProgressChanged: (controller, progress) {
              setState(() => _progress = progress / 100);
            },
            onPageCommitVisible: (controller, url) async {
              final canGoBack = await controller.canGoBack();
              final canGoForward = await controller.canGoForward();
              if (!mounted) return;
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

  Widget _buildBrowserControls(AppState appState) {
    final isConnected = _legacyHandler?.isConnected ??
        _eip1193Handler?.isConnected ??
        _tronHandler?.isConnected ??
        false;

    return BrowserControlBar(
      controller: _searchController,
      onSubmitted: _handleSearch,
      currentUrl: _currentUrl,
      canGoBack: _canGoBack,
      canGoForward: _canGoForward,
      isLoading: _isLoading,
      progress: _progress,
      isConnected: isConnected,
      urlBarTop: appState.browserUrlBarTop,
      onBack: () => _webViewController?.goBack(),
      onForward: () => _webViewController?.goForward(),
      onRefresh: () => _webViewController?.reload(),
      onCopyLink: () async {
        final url = await _webViewController?.getUrl();
        final text = url?.toString() ?? _currentUrl;
        if (text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: text));
        }
      },
      onShare: () async {
        final url = await _webViewController?.getUrl();
        final text = url?.toString() ?? _currentUrl;
        if (text.isNotEmpty) {
          SharePlus.instance.share(
            ShareParams(
              text: text,
            ),
          );
        }
      },
      onUrlBarPositionChanged: (value) => appState.setBrowserUrlBarTop(value),
      onClose: () {
        setState(() {
          _isWebViewVisible = false;
          _webViewController = null;
          _searchController.text = "";
          _searchController.clear();
        });

        try {
          _legacyHandler?.dispose();
        } catch (_) {}

        try {
          _eip1193Handler?.dispose();
        } catch (_) {}

        try {
          _tronHandler?.dispose();
        } catch (_) {}
      },
    );
  }

  Widget _buildSearchBar(AppTheme theme) {
    final appState = Provider.of<AppState>(context, listen: false);
    final searchEngineIndex = appState.state.browserSettings.searchEngineIndex;
    final searchEngine = baseSearchEngines[searchEngineIndex];
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Align(
      alignment: Alignment.center,
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 560 : 450),
        child: ListenableBuilder(
          listenable: _searchController,
          builder: (context, _) => GlassSearchBar(
            key: _searchBarKey,
            controller: _searchController,
            hint: l10n.browserPageSearchHint(searchEngine.name),
            onSubmitted: _handleSearch,
            keyboardType: TextInputType.url,
            rightIcon: _searchController.text.isNotEmpty ? AppIcon.close : null,
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 960;
    final isDesktop = screenWidth >= 960;
    final double maxWidth = isDesktop
        ? 920.0
        : isTablet
            ? 760.0
            : double.infinity;

    return SingleChildScrollView(
      padding: padding.copyWith(top: 24, bottom: 96),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
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
        errorWidget: HoverIcon(
          icon: AppIcon.warning,
          size: 30,
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
