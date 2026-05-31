import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/exchange_provider_icon.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/components/token_select_item.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

/// Bottom-sheet picker over a list of [ExchangeAsset] (already filtered to the active
/// chain by the caller). Mirrors `select_token.dart` but sources its rows from the
/// exchange bootstrap list and returns the chosen asset.
void showExchangeTokenSelectModal({
  required BuildContext context,
  required List<ExchangeAsset> assets,
  required void Function(ExchangeAsset asset) onSelected,
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
        child: _ExchangeTokenSelectContent(
          assets: assets,
          onSelected: onSelected,
        ),
      );
    },
  );
}

/// Small chain icon for the token's `chainHash`, overlaid on the token avatar. Returns
/// null when the chain can't be resolved so the avatar simply renders without a badge.
Widget? _buildNetworkBadge(AppState appState, AppTheme theme, FTokenInfo token) {
  final NetworkConfigInfo? chain;
  try {
    chain = appState.getChain(token.chainHash);
  } catch (_) {
    return null;
  }
  if (chain == null) return null;
  return Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: theme.cardBackground,
      shape: BoxShape.circle,
      border: Border.all(color: theme.cardBackground, width: 1.5),
    ),
    child: ClipOval(
      child: AsyncImage(
        url: viewChain(network: chain, theme: theme.value),
        width: 16,
        height: 16,
        fit: BoxFit.contain,
      ),
    ),
  );
}

class _ExchangeTokenSelectContent extends StatefulWidget {
  final List<ExchangeAsset> assets;
  final void Function(ExchangeAsset asset) onSelected;

  const _ExchangeTokenSelectContent({
    required this.assets,
    required this.onSelected,
  });

  @override
  State<_ExchangeTokenSelectContent> createState() =>
      _ExchangeTokenSelectContentState();
}

class _ExchangeTokenSelectContentState
    extends State<_ExchangeTokenSelectContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExchangeAsset> get _filtered {
    if (_searchQuery.isEmpty) return widget.assets;
    final query = _searchQuery.toLowerCase();
    return widget.assets
        .where((a) =>
            a.token.name.toLowerCase().contains(query) ||
            a.token.symbol.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const headerHeight = 84.0;
    const searchBarHeight = 80.0;
    const tokenItemHeight = 72.0;
    final assets = _filtered;

    final totalContentHeight = headerHeight +
        searchBarHeight +
        (assets.length * tokenItemHeight) +
        bottomPadding;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final containerHeight = totalContentHeight.clamp(0.0, maxHeight);

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartInput(
              controller: _searchController,
              hint: l10n.tokenSelectModalContentSearchHint,
              leftIconPath: 'assets/icons/search.svg',
              onChanged: (value) => setState(() => _searchQuery = value),
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: assets.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.textSecondary.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final asset = assets[index];
                final balance = BigInt.tryParse(
                        asset.token.balances[appState.accountBalanceKey] ??
                            '') ??
                    BigInt.zero;
                return TokenSelectItem(
                  ftoken: asset.token,
                  balance: balance,
                  networkBadge: _buildNetworkBadge(appState, theme, asset.token),
                  providerIcons:
                      asset.providers.map(exchangeProviderIconAsset).toList(),
                  onTap: () {
                    widget.onSelected(asset);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
