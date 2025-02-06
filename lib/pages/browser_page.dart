import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = 'https://zilpay.io';
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initWebView();
    _urlController.text = _currentUrl;
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
              _urlController.text = url;
            });
          },
          onPageFinished: (String url) async {
            // Inject your custom JavaScript here
            await _controller.runJavaScript('''
              // Your custom JavaScript injection
              console.log('ZilPay Browser Initialized');
              
              // Example: Inject ZilPay object
              window.zilPay = {
                wallet: {
                  net: 'mainnet',
                  isConnect: true,
                  // Add more wallet properties
                }
              };
            ''');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  Future<void> _refreshPage() async {
    await _controller.reload();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _refreshPage,
                builder: (
                  BuildContext context,
                  RefreshIndicatorMode refreshState,
                  double pulledExtent,
                  double refreshTriggerPullDistance,
                  double refreshIndicatorExtent,
                ) {
                  return LinearRefreshIndicator(
                    pulledExtent: pulledExtent,
                    refreshTriggerPullDistance: refreshTriggerPullDistance,
                    refreshIndicatorExtent: refreshIndicatorExtent,
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Browser Navigation Bar
                    Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Row(
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/arrow-left.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () async {
                              if (await _controller.canGoBack()) {
                                await _controller.goBack();
                              }
                            },
                          ),
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/arrow-right.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () async {
                              if (await _controller.canGoForward()) {
                                await _controller.goForward();
                              }
                            },
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _urlController,
                                decoration: InputDecoration(
                                  hintText: 'Enter URL',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: theme.textSecondary,
                                  ),
                                ),
                                style: TextStyle(
                                  color: theme.textPrimary,
                                ),
                                onSubmitted: (url) {
                                  if (!url.startsWith('http')) {
                                    url = 'https://$url';
                                  }
                                  _controller.loadRequest(Uri.parse(url));
                                },
                              ),
                            ),
                          ),
                          HoverSvgIcon(
                            assetName: 'assets/icons/refresh.svg',
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                            color: theme.textSecondary,
                            onTap: _refreshPage,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 150,
                      child: Stack(
                        children: [
                          WebViewWidget(
                            controller: _controller,
                          ),
                          if (_isLoading)
                            Center(
                              child: CircularProgressIndicator(
                                color: theme.primaryPurple,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
