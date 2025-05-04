import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/enable_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import 'dart:convert';

class ManageTokensPage extends StatefulWidget {
  const ManageTokensPage({super.key});

  @override
  State<ManageTokensPage> createState() => _ManageTokensPageState();
}

class _ManageTokensPageState extends State<ManageTokensPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<FTokenInfo> _displayTokens = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final walletTokens = appState.wallet?.tokens ?? [];
    setState(() {
      _displayTokens = walletTokens;
    });
    if (_canFetchApiTokens(appState)) {
      _loadCachedTokens();
      _fetchApiTokens();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canFetchApiTokens(AppState appState) {
    return appState.chain?.testnet != true &&
        appState.chain?.slip44 == 313 &&
        appState.account?.addrType == 0;
  }

  Future<void> _loadCachedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('legacy_zilliqa_tokens_cache');
    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      final appState = Provider.of<AppState>(context, listen: false);
      final cachedTokens = decoded
          .map((item) => FTokenInfo(
                name: item['name'],
                symbol: item['symbol'],
                decimals: item['decimals'],
                addr: item['addr'],
                addrType: 0,
                logo: item['logo'],
                balances: {},
                rate: 0,
                default_: false,
                native: false,
                chainHash: appState.chain?.chainHash ?? BigInt.zero,
              ))
          .toList();
      _updateDisplayTokens(cachedTokens);
    }
  }

  Future<void> _fetchApiTokens() async {
    setState(() => _isLoading = true);
    try {
      final apiTokens =
          await fetchTokensListZilliqaLegacy(limit: 100, offset: 0);
      final formattedTokens = apiTokens.map((token) {
        return FTokenInfo(
          name: token.name,
          symbol: token.symbol,
          decimals: token.decimals,
          addr: token.addr,
          addrType: token.addrType,
          logo:
              "https://raw.githubusercontent.com/zilpay/tokens_meta/refs/heads/master/ft/zilliqa/%{contract_address}%/%{dark,light}%.webp",
          balances: token.balances,
          rate: token.rate,
          default_: token.default_,
          native: token.native,
          chainHash: token.chainHash,
        );
      }).toList();
      _updateDisplayTokens(formattedTokens);
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(formattedTokens
          .map((token) => {
                'name': token.name,
                'symbol': token.symbol,
                'decimals': token.decimals,
                'addr': token.addr,
                'logo': token.logo,
              })
          .toList());
      await prefs.setString('legacy_zilliqa_tokens_cache', encoded);
    } catch (e) {
      debugPrint("Fetch tokens error: $e");
    } finally {
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

  Future<void> _fetchTokenByAddress(String address) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_displayTokens
        .any((token) => token.addr.toLowerCase() == address.toLowerCase())) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final meta = await fetchTokenMeta(
        addr: address,
        walletIndex: BigInt.from(appState.selectedWallet),
      );
      final logo = meta.logo != null && meta.logo!.isNotEmpty
          ? meta.logo!
              .replaceAll(
                '%{contract_address}%',
                meta.addr.toLowerCase(),
              )
              .replaceAll(
                '%{dark,light}%',
                appState.currentTheme.value == 'dark' ? 'dark' : 'light',
              )
          : null;
      final formattedMeta = FTokenInfo(
        name: meta.name,
        symbol: meta.symbol,
        decimals: meta.decimals,
        addr: meta.addr,
        addrType: meta.addrType,
        logo: logo,
        balances: meta.balances,
        rate: meta.rate,
        default_: meta.default_,
        native: meta.native,
        chainHash: meta.chainHash,
      );
      setState(() {
        _displayTokens.add(formattedMeta);
      });
    } catch (e) {
      debugPrint("Fetch token meta error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final filteredTokens = _displayTokens.where((token) {
      final query = _searchQuery.toLowerCase();
      return token.name.toLowerCase().contains(query) ||
          token.symbol.toLowerCase().contains(query) ||
          token.addr.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: "Tokens",
              onBackPressed: () => Navigator.pop(context),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: adaptivePadding, vertical: 16),
              child: SmartInput(
                controller: _searchController,
                hint: "Search tokens",
                leftIconPath: 'assets/icons/search.svg',
                rightIconPath: "assets/icons/close.svg",
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    if (value.length == 42) {
                      _fetchTokenByAddress(value);
                    }
                  });
                },
                onRightIconTap: () {
                  _searchController.text = "";
                  setState(() => _searchQuery = "");
                },
                borderColor: theme.textPrimary,
                focusedBorderColor: theme.primaryPurple,
                height: 48,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                autofocus: false,
              ),
            ),
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.modalBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchApiTokens,
                child: CustomScrollView(
                  slivers: [
                    if (filteredTokens.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(child: Text("No tokens found")),
                      )
                    else
                      SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final token = filteredTokens[index];
                              final isEnabled = appState.wallet?.tokens
                                      .any((t) => t.addr == token.addr) ??
                                  false;
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
                                  errorWidget: SvgPicture.asset(
                                    "assets/icons/warning.svg",
                                    width: 32.0,
                                    height: 32.0,
                                    colorFilter: ColorFilter.mode(
                                      theme.warning,
                                      BlendMode.srcIn,
                                    ),
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
                                    if (value) {
                                      await addFtoken(
                                        meta: token,
                                        walletIndex: BigInt.from(
                                            appState.selectedWallet),
                                      );
                                    } else {
                                      await rmFtoken(
                                        walletIndex: BigInt.from(
                                            appState.selectedWallet),
                                        tokenAddress: token.addr,
                                      );
                                    }
                                    await appState.syncData();
                                  } catch (e) {
                                    debugPrint("Toggle token error: $e");
                                  }
                                },
                              );
                            },
                            childCount: filteredTokens.length,
                          ),
                        ),
                      ),
                    if (_isLoading)
                      SliverToBoxAdapter(
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
