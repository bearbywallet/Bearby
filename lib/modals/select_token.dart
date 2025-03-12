import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/token_select_item.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;
import 'package:zilpay/l10n/app_localizations.dart';

void showTokenSelectModal({
  required BuildContext context,
  required Function(int) onTokenSelected,
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
        child: _TokenSelectModalContent(
          onTokenSelected: onTokenSelected,
        ),
      );
    },
  );
}

class _TokenSelectModalContent extends StatefulWidget {
  final Function(int) onTokenSelected;

  const _TokenSelectModalContent({
    required this.onTokenSelected,
  });

  @override
  State<_TokenSelectModalContent> createState() =>
      _TokenSelectModalContentState();
}

class _TokenSelectModalContentState extends State<_TokenSelectModalContent> {
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
    final l10n = AppLocalizations.of(context)!;

    final double headerHeight = 84.0;
    final double searchBarHeight = 80.0;
    final double tokenItemHeight = 72.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

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
              itemCount: _getFilteredTokens(appState).length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.textSecondary.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                return _buildTokenItem(
                  theme,
                  appState,
                  _getFilteredTokens(appState)[index],
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  List<FTokenInfo> _getFilteredTokens(AppState appState) {
    if (appState.wallet == null) {
      return [];
    }

    final tokens = appState.wallet!.tokens;
    return tokens
        .where((token) => token.addrType == appState.account?.addrType)
        .where((token) =>
            token.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            token.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildTokenItem(
    theme.AppTheme theme,
    AppState appState,
    FTokenInfo token,
  ) {
    final tokens = appState.wallet!.tokens;
    final tokenIndex = tokens.indexOf(token);
    final bigBalance = BigInt.tryParse(
            token.balances[appState.wallet!.selectedAccount].toString()) ??
        BigInt.zero;

    return TokenSelectItem(
      ftoken: token,
      balance: bigBalance,
      onTap: () {
        widget.onTokenSelected(tokenIndex);
        Navigator.pop(context);
      },
    );
  }
}
