import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/theme/app_theme.dart';

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
      ..addJavaScriptChannel(
        'FlutterWebView',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('Received from web: ${message.message}');
          _webViewController.runJavaScript(
            'window.postMessage(${message.message}, "*")',
          );
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
              SnackBar(content: Text('Error: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _refreshPage() => _webViewController.reload();

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
