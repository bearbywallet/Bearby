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
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'dart:convert';
import 'dart:async';

extension FTokenInfoJsonExtension on FTokenInfo {
  static FTokenInfo fromJson(Map<String, dynamic> json) {
    return FTokenInfo(
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      decimals: json['decimals'] as int,
      addr: json['addr'] as String,
      addrType: json['addrType'] as int,
      logo: json['logo'] as String?,
      balances: {},
      rate: json['rate'] as double,
      default_: json['default_'] as bool,
      native: json['native'] as bool,
      chainHash: BigInt.parse(json['chainHash'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
      'addr': addr,
      'addrType': addrType,
      'logo': logo,
      'balances': {},
      'rate': rate,
      'default_': default_,
      'native': native,
      'chainHash': chainHash.toString(),
    };
  }
}

class ManageTokensPage extends StatefulWidget {
  const ManageTokensPage({super.key});

  @override
  State<ManageTokensPage> createState() => _ManageTokensPageState();
}

class _ManageTokensPageState extends State<ManageTokensPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  List<FTokenInfo> _allTokens = [];
  bool _isLoading = false;
  Timer? _debounce;

  bool _canFetchApiTokens(AppState appState) {
    final chain = appState.chain;
    return chain != null && chain.testnet != true;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {}
    });
    _initializeTokens();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    if (_canFetchApiTokens(appState)) {
      _initializeTokens();
    }
  }

  void _initializeTokens() {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletTokens = appState.wallet?.tokens ?? [];
    setState(() {
      _allTokens = walletTokens;
    });
    if (_canFetchApiTokens(appState)) {
      _loadCachedTokens();
    }
  }

  Future<void> _loadCachedTokens() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chain = appState.chain;
    if (chain == null ||
        (chain.slip44 == 313 && appState.account?.addrType == 1)) return;
    final cacheKey = _getCacheKey(chain);
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      final cachedTokens = decoded
          .map((item) => FTokenInfoJsonExtension.fromJson(item))
          .toList();
      _updateAllTokens(cachedTokens);
    } else {
      _fetchApiTokens();
    }
  }

  Future<void> _fetchApiTokens() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.wallet?.settings.tokensListFetcher != true) {
      return;
    }

    setState(() => _isLoading = true);
    final chain = appState.chain;
    if (chain == null) return;
    String logo =
        "https://raw.githubusercontent.com/zilpay/tokens_meta/refs/heads/master/ft/${chain.shortName}/%{contract_address}%/%{dark,light}%.webp";

    try {
      List<FTokenInfo> apiTokens;
      if (chain.slip44 == 313 && appState.account?.addrType == 0) {
        apiTokens = await fetchTokensListZilliqaLegacy(limit: 200, offset: 0);
        apiTokens = apiTokens.map((token) {
          return FTokenInfo(
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimals,
            addr: token.addr,
            addrType: token.addrType,
            logo: logo,
            balances: token.balances,
            rate: 0,
            default_: false,
            native: false,
            chainHash: chain.chainHash,
          );
        }).toList();
      } else if (chain.slip44 == 60 && appState.account?.addrType == 1) {
        apiTokens = await fetchTokensEvmList(
          chainName: chain.shortName,
          chainId: chain.chainId.toInt(),
        );
        apiTokens = apiTokens.map((token) {
          return FTokenInfo(
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimals,
            addr: token.addr,
            addrType: token.addrType,
            logo: logo,
            balances: token.balances,
            rate: 0,
            default_: false,
            native: false,
            chainHash: chain.chainHash,
          );
        }).toList();
      } else {
        return;
      }

      _updateAllTokens(apiTokens);
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(chain);
      final encoded =
          jsonEncode(apiTokens.map((token) => token.toJson()).toList());
      await prefs.setString(cacheKey, encoded);
    } catch (e) {
      debugPrint("Fetch tokens error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCacheKey(NetworkConfigInfo chain) {
    if (chain.slip44 == 313) {
      return 'legacy_zilliqa_tokens_cache_${chain.shortName}';
    } else {
      return 'evm_tokens_cache_${chain.shortName}';
    }
  }

  void _updateAllTokens(List<FTokenInfo> additionalTokens) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletTokens = appState.wallet?.tokens ?? [];
    final uniqueTokens = <String, FTokenInfo>{};
    await Future.microtask(() {
      for (var token in walletTokens) {
        uniqueTokens[token.addr.toLowerCase()] = token;
      }
      for (var token in additionalTokens) {
        uniqueTokens[token.addr.toLowerCase()] = token;
      }
    });
    setState(() {
      _allTokens = uniqueTokens.values.toList();
    });
  }

  Future<void> _fetchTokenByAddress(String address) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_allTokens
        .any((token) => token.addr.toLowerCase() == address.toLowerCase())) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final meta = await fetchTokenMeta(
        addr: address,
        walletIndex: BigInt.from(appState.selectedWallet),
      );
      setState(() {
        _allTokens.add(meta);
      });
    } catch (e) {
      debugPrint("Fetch token meta error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final filteredTokens = _allTokens.where((token) {
      final query = _searchQuery.toLowerCase();
      return token.name.toLowerCase().contains(query) ||
          token.symbol.toLowerCase().contains(query) ||
          token.addr.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: "Tokens",
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 16),
                  child: SmartInput(
                    controller: _searchController,
                    hint: "Search tokens",
                    leftIconPath: 'assets/icons/search.svg',
                    rightIconPath: 'assets/icons/close.svg',
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _fetchTokenByAddress(value);
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
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (filteredTokens.isEmpty)
                          SliverToBoxAdapter(
                            child: Center(child: Text("No tokens found")),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: adaptivePadding),
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
                                        shortName:
                                            appState.chain?.shortName ?? "",
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
        ),
      ),
    );
  }
}
