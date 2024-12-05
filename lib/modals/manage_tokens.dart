import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/theme/theme_provider.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;

void showManageTokensModal({
  required BuildContext context,
  VoidCallback? onAddToken,
  Function(String)? onTokenToggle,
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
        child: _ManageTokensModalContent(
          onAddToken: onAddToken,
          onTokenToggle: onTokenToggle,
        ),
      );
    },
  );
}

class _ManageTokensModalContent extends StatefulWidget {
  final VoidCallback? onAddToken;
  final Function(String)? onTokenToggle;

  const _ManageTokensModalContent({
    this.onAddToken,
    this.onTokenToggle,
  });

  @override
  State<_ManageTokensModalContent> createState() =>
      _ManageTokensModalContentState();
}

class _ManageTokensModalContentState extends State<_ManageTokensModalContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final appState = Provider.of<AppState>(context);
    final tokens = appState.wallet?.tokens ?? [];

    // Calculate container height based on content
    final double headerHeight = 84.0; // Drag handle + padding
    final double searchBarHeight = 80.0; // Search bar + padding
    final double tokenItemHeight = 56.0; // Height per token item
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate total content height
    final double totalContentHeight = headerHeight +
        searchBarHeight +
        (tokens.length * tokenItemHeight) +
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
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartInput(
              controller: _searchController,
              hint: 'Search',
              leftIconPath: 'assets/icons/plus.svg',
              onLeftIconTap: widget.onAddToken,
              onChanged: (value) => setState(() => _searchQuery = value),
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),

          // Token List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _buildTokenItems(theme, appState),
            ),
          ),

          // Bottom Padding
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  List<Widget> _buildTokenItems(theme.AppTheme theme, AppState appState) {
    if (appState.wallet == null) {
      return [];
    }

    return appState.wallet!.tokens
        .where((token) =>
            token.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            token.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .map((token) => _TokenListItem(
              symbol: token.symbol,
              name: token.name,
              addr: token.addr,
              iconUrl: viewIcon(token.addr, "Light"),
              onToggle: (value) => widget.onTokenToggle?.call(token.addr),
              isEnabled: true,
            ))
        .toList();
  }
}

class _TokenListItem extends StatelessWidget {
  final String symbol;
  final String name;
  final String addr;
  final String iconUrl;
  final Function(bool)? onToggle;
  final bool isEnabled;

  const _TokenListItem({
    required this.symbol,
    required this.name,
    required this.addr,
    required this.iconUrl,
    required this.isEnabled,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SvgPicture.network(
              iconUrl,
              width: 32,
              height: 32,
              placeholderBuilder: (context) => SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
