import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/config/search_engines.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/pages/web_view.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final appState = Provider.of<AppState>(context, listen: false);
    appState.syncConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          initialUrl: url,
        ),
      ),
    );
  }

  bool isDomainName(String input) {
    final domainPart = input.split(':')[0];
    final domainRegex = RegExp(
        r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$');
    return domainRegex.hasMatch(domainPart);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final padding = EdgeInsets.symmetric(
        horizontal: AdaptiveSize.getAdaptivePadding(context, 16));
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final connections = appState.connections;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Scaffold(
            backgroundColor: theme.background,
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Connected'),
                    Tab(text: 'Explore'),
                  ],
                  labelStyle: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                  indicatorColor: theme.primaryPurple,
                  labelColor: theme.textPrimary,
                  unselectedLabelColor: theme.textSecondary,
                  indicatorSize: TabBarIndicatorSize.label,
                  splashFactory: NoSplash.splashFactory,
                  dividerColor: Colors.transparent,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConnectedTab(connections, theme, padding),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No apps to explore yet',
                                style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: _buildSearchBar(theme),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppTheme theme) {
    final appState = Provider.of<AppState>(context);
    final searchEngineIndex = appState.state.browserSettings.searchEngineIndex;
    final searchEngine = baseSearchEngines[searchEngineIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartInput(
          controller: _searchController,
          hint: 'Search with ${searchEngine.name} or enter address',
          leftIconPath: 'assets/icons/search.svg',
          rightIconPath: "assets/icons/close.svg",
          onChanged: (value) {},
          onSubmitted: _handleSearch,
          onRightIconTap: () {
            _searchController.text = "";
          },
          borderColor: theme.textPrimary,
          focusedBorderColor: theme.primaryPurple,
          height: 48,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          autofocus: false,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildConnectedTab(
      List<ConnectionInfo> connections, AppTheme theme, EdgeInsets padding) {
    if (connections.isEmpty) {
      return Center(
        child: Text(
          'No connected apps',
          style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      padding: padding.copyWith(top: 32, bottom: 16),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        final url = 'https://${connection.domain}';
        return _buildConnectedTile(
          connection.title,
          connection.favicon ?? 'https://${connection.domain}/favicon.ico',
          url,
          theme,
        );
      },
    );
  }

  Widget _buildConnectedTile(
      String label, String iconUrl, String url, AppTheme theme) {
    return TileButton(
      title: label,
      icon: AsyncImage(
        url: iconUrl,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorWidget: HoverSvgIcon(
          assetName: 'assets/icons/default.svg',
          width: 24,
          height: 24,
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
