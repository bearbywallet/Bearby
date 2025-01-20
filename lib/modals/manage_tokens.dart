import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;

void showManageTokensModal({
  required BuildContext context,
  VoidCallback? onAddToken,
  Function(String)? onTokenToggle,
}) {
  showModalBottomSheet<void>(
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
        ),
      );
    },
  );
}

class _ManageTokensModalContent extends StatefulWidget {
  final VoidCallback? onAddToken;

  const _ManageTokensModalContent({
    this.onAddToken,
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
    final theme = Provider.of<AppState>(context).currentTheme;
    final appState = Provider.of<AppState>(context);
    final tokens = appState.wallet?.tokens ?? [];

    final double headerHeight = 84.0;
    final double searchBarHeight = 80.0; // Search bar + padding
    final double tokenItemHeight = 56.0; // Height per token item
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate total content height
    final double totalContentHeight = headerHeight +
        searchBarHeight +
        (tokens.length * tokenItemHeight) +
        bottomPadding;

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
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _buildTokenItems(theme, appState),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  List<Widget> _buildTokenItems(theme.AppTheme theme, AppState appState) {
    if (appState.wallet == null) {
      return [];
    }

    final providers = appState.state.providers;

    return appState.wallet!.tokens
        .where((token) =>
            token.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            token.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .map((token) => _TokenListItem(
              symbol: token.symbol,
              name: token.name,
              addr: token.addr,
              isDefault: token.default_,
              iconUrl: token.logo ??
                  viewIcon(
                    token.addr,
                    appState.state.appearances,
                    providers[token.providerIndex.toInt()].chainId,
                  ),
              onToggle: (value) async {
                if (!value) {
                  final int index = appState.wallet!.tokens
                      .indexWhere((t) => t.addr == token.addr);

                  if (index == -1) {
                    return;
                  }

                  try {
                    await rmFtoken(
                      walletIndex: BigInt.from(appState.selectedWallet),
                      tokenIndex: BigInt.from(index),
                    );
                    await appState.syncData();
                  } catch (e) {
                    debugPrint("remove token error: $e");
                  }
                }
              },
              isEnabled: !token.default_,
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
  final bool isDefault;

  const _TokenListItem({
    required this.symbol,
    required this.name,
    required this.addr,
    required this.iconUrl,
    required this.isEnabled,
    required this.isDefault,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    const double iconSize = 32.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AsyncImage(
                url: iconUrl,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorWidget: Blockies(
                  seed: addr,
                  color: getWalletColor(0),
                  bgColor: theme.primaryPurple,
                  spotColor: theme.background,
                  size: 8,
                ),
                loadingWidget: const Center(
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDefault ? true : isEnabled,
            onChanged: onToggle,
            activeColor: isDefault ? theme.textSecondary : theme.success,
          ),
        ],
      ),
    );
  }
}
