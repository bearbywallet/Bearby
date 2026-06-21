import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/token_select_item.dart';
import 'package:bearby/components/token_select_sheet.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

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
        child: _TokenSelectContent(
          onTokenSelected: onTokenSelected,
        ),
      );
    },
  );
}

class _TokenSelectContent extends StatefulWidget {
  final Function(int) onTokenSelected;

  const _TokenSelectContent({required this.onTokenSelected});

  @override
  State<_TokenSelectContent> createState() => _TokenSelectContentState();
}

class _TokenSelectContentState extends State<_TokenSelectContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FTokenInfo> _filtered(AppState appState) {
    if (appState.wallet == null) return [];

    return appState.wallet!.tokens
        .where((t) => t.addrType == appState.account?.addrType)
        .where((t) =>
            _searchQuery.isEmpty ||
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final tokens = _filtered(appState);

    return TokenSelectSheet(
      searchController: _searchController,
      searchHint: l10n.tokenSelectModalContentSearchHint,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        final token = tokens[index];
        final tokenIndex = appState.wallet!.tokens.indexOf(token);
        final balance =
            BigInt.tryParse(token.balances[appState.accountBalanceKey] ?? '') ??
                BigInt.zero;

        return TokenSelectItem(
          ftoken: token,
          balance: balance,
          onTap: () {
            widget.onTokenSelected(tokenIndex);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
