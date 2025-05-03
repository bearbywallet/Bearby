import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zilpay/components/enable_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;
import 'dart:convert';

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
  List<FTokenInfo> _displayTokens = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTokens({bool forceRefresh = false}) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletTokens = appState.wallet?.tokens ?? [];

    if (walletTokens.isNotEmpty) {
      setState(() {
        _displayTokens = walletTokens;
      });
    }

    if (appState.chain?.testnet == true ||
        appState.chain?.slip44 != 313 ||
        appState.account?.addrType != 0) {
      return;
    }

    if (forceRefresh) {
      setState(() => _isLoading = true);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('legacy_zilliqa_tokens_cache');

      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final cachedTokens = decoded
            .map((item) => FTokenInfo(
                  name: item['name'],
                  symbol: item['symbol'],
                  decimals: item['decimals'],
                  addr: item['addr'],
                  addrType: 0,
                  logo: item['logo'],
                  balances: Map(),
                  rate: 0,
                  default_: false,
                  native: false,
                  chainHash: appState.chain?.chainHash ?? BigInt.zero,
                ))
            .toList();
        _updateDisplayTokens(cachedTokens);
      }
    }

    if (forceRefresh || _displayTokens.isEmpty) {
      setState(() => _isLoading = true);
      try {
        List<FTokenInfo> tokens =
            await fetchTokensListZilliqaLegacy(limit: 100, offset: 0);

        if (appState.wallet?.tokens.isNotEmpty == true) {
          tokens = tokens
              .map((t) => FTokenInfo(
                    name: t.name,
                    symbol: t.symbol,
                    decimals: t.decimals,
                    addr: t.addr,
                    addrType: t.addrType,
                    logo:
                        "https://meta.viewblock.io/zilliqa.%{contract_address}%/logo?t=%{light,dark}%",
                    balances: t.balances,
                    rate: t.rate,
                    default_: t.default_,
                    native: t.native,
                    chainHash: t.chainHash,
                  ))
              .toList();
        }

        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(tokens
            .map((token) => {
                  'name': token.name,
                  'symbol': token.symbol,
                  'decimals': token.decimals,
                  'addr': token.addr,
                  'logo': token.logo,
                })
            .toList());
        await prefs.setString('legacy_zilliqa_tokens_cache', encoded);
        _updateDisplayTokens(tokens);
      } catch (e) {
        debugPrint("Fetch tokens error: $e");
      }
      setState(() => _isLoading = false);
    }
  }

  void _updateDisplayTokens(List<FTokenInfo> additionalTokens) {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletTokens = appState.wallet?.tokens ?? [];
    final uniqueTokens = <String, FTokenInfo>{};

    for (var token in walletTokens) {
      uniqueTokens[token.addr] = token;
    }

    for (var token in additionalTokens) {
      uniqueTokens[token.addr] = token;
    }

    setState(() {
      _displayTokens = uniqueTokens.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final appState = Provider.of<AppState>(context);

    final double headerHeight = 84.0;
    final double searchBarHeight = 80.0;
    final double tokenItemHeight = 56.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    final double totalContentHeight = headerHeight +
        searchBarHeight +
        (_displayTokens.length * tokenItemHeight) +
        bottomPadding +
        (_isLoading ? 4.0 : 0.0);

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
              hint: "Search tokens",
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
            child: RefreshIndicator(
              onRefresh: () => _loadTokens(forceRefresh: true),
              child: _displayTokens.isEmpty && !_isLoading
                  ? const Center(child: Text("No tokens available"))
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children:
                          _buildTokenItems(theme, appState, _displayTokens),
                    ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  List<Widget> _buildTokenItems(
      theme.AppTheme theme, AppState appState, List<FTokenInfo> tokens) {
    if (appState.wallet == null) {
      return [const Center(child: Text("Wallet not found"))];
    }

    final filteredTokens = tokens
        .where((token) =>
            token.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            token.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredTokens.isEmpty) {
      return [const Center(child: Text("No matching tokens"))];
    }

    return filteredTokens.map((token) {
      final isEnabled =
          appState.wallet!.tokens.any((t) => t.addr == token.addr);
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
          try {
            if (!value) {
              await rmFtoken(
                walletIndex: BigInt.from(appState.selectedWallet),
                tokenAddress: token.addr,
              );
            } else {
              await addFtoken(
                meta: token,
                walletIndex: BigInt.from(appState.selectedWallet),
              );
            }
            await appState.syncData();
          } catch (e) {
            debugPrint("Toggle token error: $e");
          }
        },
      );
    }).toList();
  }
}
