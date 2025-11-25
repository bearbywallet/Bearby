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
import 'package:zilpay/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:async';

const String _deletedTokensKey = 'deleted_tokens_cache';

enum TokenSearchError { fetchError, wrongChain }

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

  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _debounce;
  BigInt? _currentChainHash;
  int? _currentAddrType;

  FTokenInfo? _foundToken;
  TokenSearchError? _searchError;
  List<FTokenInfo> _deletedTokens = [];
  List<FTokenInfo> _suggestedTokens = [];

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
        _loadDeletedTokens();
        _loadSuggestedTokens();
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
        _searchController.clear();
        _searchQuery = '';
        _foundToken = null;
        _searchError = null;
        _deletedTokens = [];
        _suggestedTokens = [];
      });
      _loadDeletedTokens();
      _loadSuggestedTokens();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _getDeletedTokensCacheKey(BigInt chainHash) {
    return '${_deletedTokensKey}_$chainHash';
  }

  Future<void> _loadDeletedTokens() async {
    if (_currentChainHash == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _getDeletedTokensCacheKey(_currentChainHash!);
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null && mounted) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      setState(() {
        _deletedTokens =
            decoded.map((item) => FTokenInfoJsonExtension.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveDeletedTokens() async {
    if (_currentChainHash == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _getDeletedTokensCacheKey(_currentChainHash!);
    await prefs.setString(
      cacheKey,
      jsonEncode(_deletedTokens.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _clearDeletedTokens() async {
    if (_currentChainHash == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _getDeletedTokensCacheKey(_currentChainHash!);
    await prefs.remove(cacheKey);

    if (mounted) {
      setState(() {
        _deletedTokens = [];
      });
    }
  }

  bool _canFetchApiTokens(AppState appState) {
    final chain = appState.chain;
    return chain != null &&
        chain.testnet != true &&
        appState.wallet?.settings.tokensListFetcher == true;
  }

  Future<void> _loadSuggestedTokens() async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    if (!_canFetchApiTokens(appState)) return;

    setState(() => _isLoading = true);

    try {
      final tokens = await autoHintTokens(
        walletIndex: BigInt.from(appState.selectedWallet),
      );

      if (mounted) {
        setState(() {
          _suggestedTokens = tokens;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch suggested tokens: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isTokenAlreadyAdded(FTokenInfo token, AppState appState) {
    final walletTokens = appState.wallet?.tokens ?? [];
    return walletTokens
        .any((t) => t.addr.toLowerCase() == token.addr.toLowerCase());
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      _foundToken = null;
      _searchError = null;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final trimmed = query.trim();
    if (trimmed.startsWith('0x') || trimmed.startsWith('zil1')) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _fetchTokenByAddress(trimmed);
      });
    }
  }

  Future<void> _fetchTokenByAddress(String address) async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      final meta = await fetchTokenMeta(
        addr: address,
        walletIndex: BigInt.from(appState.selectedWallet),
      );

      if (mounted) {
        setState(() {
          _foundToken = meta;
          _searchError = null;
        });
      }
    } catch (e) {
      debugPrint("Fetch token meta error: $e");
      if (mounted) {
        setState(() {
          _searchError = TokenSearchError.fetchError;
          _foundToken = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTokenToggle(FTokenInfo token, bool isEnabled) async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final chain = appState.chain;

    if (chain == null || _currentChainHash == null) return;

    if (token.chainHash != _currentChainHash) {
      setState(() {
        _searchError = TokenSearchError.wrongChain;
      });
      return;
    }

    final isAlreadyAdded = _isTokenAlreadyAdded(token, appState);

    try {
      if (isAlreadyAdded && !isEnabled) {
        if (token.native) return;

        await rmFtoken(
          walletIndex: BigInt.from(appState.selectedWallet),
          tokenAddress: token.addr,
        );

        final alreadyInDeleted = _deletedTokens
            .any((t) => t.addr.toLowerCase() == token.addr.toLowerCase());
        if (!alreadyInDeleted) {
          setState(() {
            _deletedTokens.add(token);
          });
          await _saveDeletedTokens();
        }
      } else if (!isAlreadyAdded && isEnabled) {
        await addFtoken(
          meta: token,
          walletIndex: BigInt.from(appState.selectedWallet),
        );

        setState(() {
          _deletedTokens.removeWhere(
              (t) => t.addr.toLowerCase() == token.addr.toLowerCase());
        });
        await _saveDeletedTokens();

        if (_foundToken != null &&
            _foundToken!.addr.toLowerCase() == token.addr.toLowerCase()) {
          setState(() {
            _foundToken = null;
            _searchController.clear();
            _searchQuery = '';
          });
        }
      }

      await appState.syncData();
    } catch (e) {
      debugPrint("Toggle token error: $e");
      await appState.syncData();
    }
  }

  List<FTokenInfo> _getActiveTokens(AppState appState) {
    final chain = appState.chain;
    final account = appState.account;
    if (chain == null || account == null) return [];

    return appState.wallet?.tokens
            .where((t) =>
                t.chainHash == chain.chainHash && t.addrType == account.addrType)
            .toList() ??
        [];
  }

  List<FTokenInfo> _filterTokens(List<FTokenInfo> tokens) {
    if (_searchQuery.isEmpty ||
        _searchQuery.startsWith('0x') ||
        _searchQuery.startsWith('zil1')) {
      return tokens;
    }

    final query = _searchQuery.toLowerCase();
    return tokens.where((token) {
      return token.name.toLowerCase().contains(query) ||
          token.symbol.toLowerCase().contains(query);
    }).toList();
  }

  bool _isTokenInDeletedList(FTokenInfo token) {
    return _deletedTokens
        .any((t) => t.addr.toLowerCase() == token.addr.toLowerCase());
  }

  List<FTokenInfo> _getFilteredSuggestedTokens(AppState appState) {
    final chainTokens = _suggestedTokens
        .where((t) => t.chainHash == _currentChainHash)
        .toList();
    final filtered = _filterTokens(chainTokens);

    return filtered
        .where((t) =>
            !_isTokenAlreadyAdded(t, appState) && !_isTokenInDeletedList(t))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final activeTokens = _filterTokens(_getActiveTokens(appState));
    final filteredDeletedTokens = _filterTokens(_deletedTokens);
    final filteredSuggestedTokens = _getFilteredSuggestedTokens(appState);

    String? getErrorText() {
      if (_searchError == null) return null;
      switch (_searchError!) {
        case TokenSearchError.fetchError:
          return l10n.manageTokensFetchError;
        case TokenSearchError.wrongChain:
          return l10n.manageTokensWrongChain;
      }
    }

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
                    title: l10n.manageTokensPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 16),
                  child: SmartInput(
                    controller: _searchController,
                    hint: l10n.manageTokensSearchHint,
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
                if (_isLoading)
                  const LinearProgressIndicator(),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    children: [
                      if (_searchError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            getErrorText()!,
                            style: TextStyle(color: theme.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_foundToken != null &&
                          !_isTokenAlreadyAdded(_foundToken!, appState))
                        _buildTokenSection(
                          title: l10n.manageTokensFoundToken,
                          tokens: [_foundToken!],
                          appState: appState,
                          theme: theme,
                          isEnabled: false,
                        ),
                      if (activeTokens.isNotEmpty)
                        _buildTokenSection(
                          tokens: activeTokens,
                          appState: appState,
                          theme: theme,
                          isEnabled: true,
                        ),
                      if (filteredDeletedTokens.isNotEmpty)
                        _buildTokenSection(
                          title: l10n.manageTokensDeletedTokens,
                          tokens: filteredDeletedTokens,
                          appState: appState,
                          theme: theme,
                          isEnabled: false,
                          showClearButton: true,
                          onClear: _clearDeletedTokens,
                          clearText: l10n.manageTokensClear,
                        ),
                      if (filteredSuggestedTokens.isNotEmpty)
                        _buildTokenSection(
                          title: l10n.manageTokensSuggestedTokens,
                          tokens: filteredSuggestedTokens,
                          appState: appState,
                          theme: theme,
                          isEnabled: false,
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenSection({
    String? title,
    required List<FTokenInfo> tokens,
    required AppState appState,
    required dynamic theme,
    required bool isEnabled,
    bool showClearButton = false,
    VoidCallback? onClear,
    String? clearText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null || showClearButton)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (showClearButton && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Text(
                      clearText ?? "Clear",
                      style: TextStyle(
                        color: theme.primaryPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ...tokens.map((token) => EnableCard(
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              isDefault: token.native,
              isEnabled: isEnabled,
              onToggle: (value) => _handleTokenToggle(token, value),
            )),
      ],
    );
  }
}
