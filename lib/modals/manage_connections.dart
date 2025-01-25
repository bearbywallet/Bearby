import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;

void showConnectedDappsModal({
  required BuildContext context,
  Function(String)? onDappDisconnect,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ConnectedDappsModalContent(
          onDappDisconnect: onDappDisconnect,
        ),
      );
    },
  );
}

class _ConnectedDappsModalContent extends StatefulWidget {
  final Function(String)? onDappDisconnect;

  const _ConnectedDappsModalContent({
    this.onDappDisconnect,
  });

  @override
  State<_ConnectedDappsModalContent> createState() =>
      _ConnectedDappsModalContentState();
}

class _ConnectedDappsModalContentState
    extends State<_ConnectedDappsModalContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final appState = Provider.of<AppState>(context);
    final connectedDapps = appState.connections;

    // Calculate container height based on content
    final double headerHeight = 84.0;
    final double searchBarHeight = 80.0;
    final double dappItemHeight = 72.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate total content height
    final double totalContentHeight = headerHeight +
        searchBarHeight +
        (connectedDapps.length * dappItemHeight) +
        bottomPadding;

    // Limit height to 70% of screen height
    final double maxHeight = MediaQuery.of(context).size.height * 0.7;
    final double containerHeight = totalContentHeight.clamp(0.0, maxHeight);

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.textSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartInput(
              controller: _searchController,
              hint: 'Search DApps',
              onChanged: (value) => setState(() => _searchQuery = value),
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),

          // DApps List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _buildDappItems(theme, appState),
            ),
          ),

          // Bottom Padding
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  List<Widget> _buildDappItems(theme.AppTheme theme, AppState appState) {
    if (appState.wallet == null) {
      return [];
    }

    final filteredDapps = appState.connections
        .where((dapp) =>
            dapp.domain.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dapp.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final List<Widget> items = [];
    for (var i = 0; i < filteredDapps.length; i++) {
      final dapp = filteredDapps[i];
      items.add(
        _DappListItem(
          name: dapp.title,
          url: dapp.domain,
          iconUrl: dapp.favicon ?? "",
          lastConnected: fromLargeBigInt(dapp.lastConnected),
          onDisconnect: () => widget.onDappDisconnect?.call(dapp.domain),
        ),
      );

      // Add divider if not the last item
      if (i < filteredDapps.length - 1) {
        items.add(
          Divider(
            height: 1,
            color: theme.textSecondary.withValues(alpha: 0.1),
          ),
        );
      }
    }

    return items;
  }

  DateTime fromLargeBigInt(BigInt timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
  }
}

class _DappListItem extends StatelessWidget {
  final String name;
  final String url;
  final String iconUrl;
  final DateTime lastConnected;
  final VoidCallback? onDisconnect;

  const _DappListItem({
    required this.name,
    required this.url,
    required this.iconUrl,
    required this.lastConnected,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    const double iconSize = 40.0;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                iconUrl,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.link,
                        size: 24,
                        color: theme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.textSecondary.withValues(alpha: 0.5),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connected ${_formatLastConnected(lastConnected)}',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDisconnect,
            icon: SvgPicture.asset(
              'assets/icons/disconnect.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(theme.danger, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastConnected(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
