import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/enable_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;
import 'package:zilpay/l10n/app_localizations.dart';

void showManageTokensModal({
  required BuildContext context,
  VoidCallback? onAddToken,
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
    final l10n = AppLocalizations.of(context)!;

    final double headerHeight = 84.0;
    final double searchBarHeight = 80.0;
    final double tokenItemHeight = 56.0;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
              hint: l10n.manageTokensModalContentSearchHint,
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

    return appState.wallet!.tokens
        .where((token) =>
            token.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            token.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .where((token) => token.addrType == appState.account?.addrType)
        .map((token) {
      final isEnabled = !token.default_;
      return EnableCard(
        title: token.symbol,
        name: token.name,
        iconWidget: AsyncImage(
          url: processTokenLogo(
            token: token,
            shortName: appState.chain?.shortName ?? "",
            theme: theme.value,
          ),
          width: 32.0,
          height: 32.0,
          fit: BoxFit.contain,
          errorWidget: Blockies(
            seed: token.addr,
            color: theme.secondaryPurple,
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
        isDefault: token.native,
        isEnabled: isEnabled,
        onToggle: (value) async {
          if (!value) {
            try {
              await rmFtoken(
                walletIndex: BigInt.from(appState.selectedWallet),
                tokenAddress: token.addr,
              );
              await appState.syncData();
            } catch (e) {
              debugPrint("remove token error: $e");
            }
          }
        },
      );
    }).toList();
  }
}
