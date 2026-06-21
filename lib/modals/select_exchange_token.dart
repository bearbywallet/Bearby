import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/exchange_state.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/components/token_select_item.dart';
import 'package:bearby/components/token_select_sheet.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

/// Bottom-sheet picker that reactively sources its token list from
/// [ExchangeState] via [assetSelector] so it stays in sync across both
/// bootstrap phases (candidate list → validated list after eager probing).
///
/// [ExchangeState] is route-scoped (provided in the exchange GoRoute builder),
/// so we capture it from the caller's context and pass it directly — the
/// bottom-sheet's own context lives outside that provider scope.
void showExchangeTokenSelectModal({
  required BuildContext context,
  required List<ExchangeAsset> Function(ExchangeState) assetSelector,
  required void Function(ExchangeAsset asset) onSelected,
}) {
  // Resolve ExchangeState from the *caller's* context while we're still inside
  // the ChangeNotifierProvider<ExchangeState> scope.
  final exchangeState = context.read<ExchangeState>();

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _ExchangeTokenSelectContent(
          exchangeState: exchangeState,
          assetSelector: assetSelector,
          onSelected: onSelected,
        ),
      );
    },
  );
}

class _ExchangeTokenSelectContent extends StatefulWidget {
  final ExchangeState exchangeState;
  final List<ExchangeAsset> Function(ExchangeState) assetSelector;
  final void Function(ExchangeAsset asset) onSelected;

  const _ExchangeTokenSelectContent({
    required this.exchangeState,
    required this.assetSelector,
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
  void initState() {
    super.initState();
    widget.exchangeState.addListener(_onExchangeChanged);
  }

  @override
  void dispose() {
    widget.exchangeState.removeListener(_onExchangeChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onExchangeChanged() {
    if (mounted) setState(() {});
  }

  List<ExchangeAsset> _filtered(List<ExchangeAsset> assets) {
    if (_searchQuery.isEmpty) return assets;
    final query = _searchQuery.toLowerCase();
    return assets
        .where((a) =>
            a.token.name.toLowerCase().contains(query) ||
            a.token.symbol.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final assets = _filtered(widget.assetSelector(widget.exchangeState));

    return TokenSelectSheet(
      searchController: _searchController,
      searchHint: l10n.tokenSelectModalContentSearchHint,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final balance = BigInt.tryParse(
                asset.token.balances[appState.accountBalanceKey] ?? '') ??
            BigInt.zero;
        return TokenSelectItem(
          ftoken: asset.token,
          balance: balance,
          networkBadge: TokenAvatar.buildNetworkBadge(
              appState, appState.currentTheme, asset.token,
              badgeSize: TokenAvatar.defaultBadgeSize(40)),
          providerIcons:
              asset.providers.map((p) => p.common.iconAsset).toList(),
          onTap: () {
            widget.onSelected(asset);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
