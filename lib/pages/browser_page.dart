import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
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
    if (value.isNotEmpty) {
      String query = value.trim();
      String url = query;

      final uri = Uri.tryParse(query);
      if (uri != null && (uri.hasScheme && uri.hasAuthority)) {
        url = query.startsWith('http://') || query.startsWith('https://')
            ? query
            : 'https://$query';
      } else {
        if (isDomainName(query)) {
          url = 'https://$query';
        } else {
          url = 'https://duckduckgo.com/?q=${Uri.encodeQueryComponent(query)}';
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WebViewPage(initialUrl: url)),
      );
    }
  }

  bool isDomainName(String input) {
    final domainRegex = RegExp(
        r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$');
    return domainRegex.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final padding = EdgeInsets.symmetric(
        horizontal: AdaptiveSize.getAdaptivePadding(context, 16));
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final connections = appState.connections;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Explore'),
                Tab(text: 'Connected'),
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
              dividerColor: Colors.transparent, // Убирает белую полоску
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                  _buildConnectedTab(connections, theme, padding),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
              child: SmartInput(
                controller: _searchController,
                hint: 'Search or enter address',
                leftIconPath: 'assets/icons/search.svg',
                onChanged: (value) {},
                onSubmitted: _handleSearch,
                borderColor: theme.textPrimary,
                focusedBorderColor: theme.primaryPurple,
                height: 48,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                autofocus: false,
                keyboardType: TextInputType.url,
              ),
            ),
          ],
        ),
      ),
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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WebViewPage(initialUrl: url)),
        );
      },
      backgroundColor: theme.cardBackground,
      textColor: theme.primaryPurple,
    );
  }
}
