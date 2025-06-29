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
import 'package:zilpay/src/rust/models/account.dart';
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
      balances: const {},
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
  List<FTokenInfo> _allTokens = [];
  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _debounce;
  BigInt? _currentChainHash;
  int? _currentAddrType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (mounted) {
        setState(() {
          _currentChainHash = appState.chain?.chainHash;
          _currentAddrType = appState.account?.addrType;
        });
        _refreshTokens();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    if ((appState.chain?.chainHash != _currentChainHash ||
            appState.account?.addrType != _currentAddrType) &&
        mounted) {
      setState(() {
        _currentChainHash = appState.chain?.chainHash;
        _currentAddrType = appState.account?.addrType;
        _allTokens = [];
        _searchController.clear();
        _searchQuery = '';
        _isLoading = false;
        _debounce?.cancel();
      });
      _refreshTokens();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _canFetchApiTokens(AppState appState) {
    final chain = appState.chain;
    return chain != null &&
        chain.testnet != true &&
        appState.wallet?.settings.tokensListFetcher == true;
  }

  String _getCacheKey(NetworkConfigInfo chain, AccountInfo account) {
    return '${chain.shortName}_${account.addrType}_tokens_cache';
  }

  Future<void> _refreshTokens({bool force = false}) async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final chain = appState.chain;
      final account = appState.account;
      if (chain == null || account == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final walletTokens = appState.wallet?.tokens
              .where((t) =>
                  t.chainHash == chain.chainHash &&
                  t.addrType == account.addrType)
              .toList() ??
          [];
      List<FTokenInfo> remoteTokens = [];
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(chain, account);

      if (!force) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final List<dynamic> decoded = jsonDecode(cachedData);
          remoteTokens = decoded
              .map((item) => FTokenInfoJsonExtension.fromJson(item))
              .toList();
        }
      }

      if ((remoteTokens.isEmpty || force) && _canFetchApiTokens(appState)) {
        List<FTokenInfo> apiTokens = [];
        String logo =
            "https://raw.githubusercontent.com/zilpay/tokens_meta/refs/heads/master/ft/${chain.shortName}/%{contract_address}%/%{dark,light}%.webp";

        if (chain.slip44 == 313 && appState.account?.addrType == 0) {
          apiTokens = await fetchTokensListZilliqaLegacy(limit: 200, offset: 0);
        } else if (chain.slip44 == 60 && appState.account?.addrType == 1) {
          apiTokens = await fetchTokensEvmList(
            chainName: chain.shortName,
            chainId: chain.chainId.toInt(),
          );
        }

        remoteTokens = apiTokens.map((token) {
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

        await prefs.setString(cacheKey,
            jsonEncode(remoteTokens.map((token) => token.toJson()).toList()));
      }

      _mergeAndSetTokens(walletTokens, remoteTokens);
    } catch (e) {
      debugPrint("Refresh tokens error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mergeAndSetTokens(
      List<FTokenInfo> walletTokens, List<FTokenInfo> remoteTokens) {
    final uniqueTokens = <String, FTokenInfo>{};

    for (var token in remoteTokens) {
      uniqueTokens[token.addr.toLowerCase()] = token;
    }
    for (var token in walletTokens) {
      uniqueTokens[token.addr.toLowerCase()] = token;
    }

    if (mounted) {
      setState(() {
        _allTokens = uniqueTokens.values.toList();
      });
    }
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 30 && mounted) {
        _fetchTokenByAddress(query);
      }
    });
  }

  Future<void> _fetchTokenByAddress(String address) async {
    if (!mounted) return;
    if (_allTokens
        .any((token) => token.addr.toLowerCase() == address.toLowerCase())) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final meta = await fetchTokenMeta(
        addr: address,
        walletIndex: BigInt.from(appState.selectedWallet),
      );
      final exists = _allTokens
          .any((t) => t.addr.toLowerCase() == meta.addr.toLowerCase());
      if (!exists && mounted) {
        setState(() {
          _allTokens.add(meta);
        });
      }
    } catch (e) {
      debugPrint("Fetch token meta error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onToggleToken(FTokenInfo token, bool isEnabled) async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (isEnabled) {
        await addFtoken(
          meta: token,
          walletIndex: BigInt.from(appState.selectedWallet),
        );
      } else {
        await rmFtoken(
          walletIndex: BigInt.from(appState.selectedWallet),
          tokenAddress: token.addr,
        );
      }
      await appState.syncData();
    } catch (e) {
      debugPrint("Toggle token error: $e");
      await appState.syncData();
    }
  }

  @override
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
                    hint: "Search tokens or paste address",
                    leftIconPath: 'assets/icons/search.svg',
                    rightIconPath: 'assets/icons/close.svg',
                    onChanged: _onSearchChanged,
                    onRightIconTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
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
                    onRefresh: () => _refreshTokens(force: true),
                    child: Stack(
                      children: [
                        if (filteredTokens.isEmpty && !_isLoading)
                          const Center(child: Text("No tokens found")),
                        CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: adaptivePadding),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final token = filteredTokens[index];
                                    final isEnabled = appState.wallet?.tokens
                                            .any((t) =>
                                                t.addr.toLowerCase() ==
                                                token.addr.toLowerCase()) ??
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
                                      onToggle: (value) =>
                                          _onToggleToken(token, value),
                                    );
                                  },
                                  childCount: filteredTokens.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoading)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
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
