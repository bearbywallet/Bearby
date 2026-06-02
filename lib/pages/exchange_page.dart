import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/input_amount.dart';
import 'package:bearby/components/jazzicon.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/number_keyboard.dart';
import 'package:bearby/components/skeleton_box.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/select_exchange_token.dart';
import 'package:bearby/modals/exchange_confirm.dart';
import 'package:bearby/modals/swap_settings.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/api/exchange.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

enum _OrderType { swap, limit, buySell }

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> with StatusBarMixin {
  static const int _slippageBps = 50; // 0.5%
  static const Duration _quoteDebounce = Duration(milliseconds: 400);

  late final AppState _appState;
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  Timer? _quoteTimer;

  _OrderType _orderType = _OrderType.swap;

  bool _loadingAssets = true;
  String? _assetsError;
  // "You pay" — our tokens on the active network (source = active wallet chain).
  List<ExchangeAsset> _assets = const [];
  // "You get" — every Uniswap-supported token on the active chain (same-chain swaps only).
  List<ExchangeAsset> _getAssets = const [];
  ExchangeAsset? _fromAsset;
  ExchangeAsset? _toAsset;

  String _amount = "0";
  bool _hasDecimalPoint = false;

  bool _loadingQuote = false;
  // All provider quotes for the current input (sorted best-first); `_selectedQuote` is the one
  // driving "You get" and the swap — auto-set to the best, overridable via the provider picker.
  List<ExchangeQuoteInfo> _quotes = const [];
  ExchangeQuoteInfo? _selectedQuote;

  // Active chain at the last bootstrap — used to re-bootstrap when the network changes (the page
  // is kept alive in a StatefulShellBranch, so initState runs only once).
  BigInt? _lastChainHash;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    _lastChainHash = _appState.wallet?.chainHash;
    _appState.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _quoteTimer?.cancel();
    _btnController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    final hash = _appState.wallet?.chainHash;
    if (hash == _lastChainHash) return;
    _lastChainHash = hash;
    _quoteTimer?.cancel();
    setState(() {
      _amount = "0";
      _hasDecimalPoint = false;
      _quotes = const [];
      _selectedQuote = null;
    });
    _bootstrap();
  }

  // --- data ---------------------------------------------------------------

  Future<void> _bootstrap() async {
    setState(() {
      _loadingAssets = true;
      _assetsError = null;
    });

    try {
      final all = await bootstrapExchangeProviders();
      final chainHash = _appState.wallet?.chainHash;

      // Uniswap routes a single hop on ONE chain, so both the "pay" and "get" sides live
      // on the wallet's active chain. (Cross-chain bridging will arrive later as a
      // separate provider, e.g. Thorchain.)
      final pay = all
          .where((a) => a.token.chainHash == chainHash && _isSwappableEvm(a))
          .toList();
      final get = pay;

      ExchangeAsset? from;
      ExchangeAsset? to;
      if (pay.isNotEmpty) {
        from = pay.firstWhere((a) => a.token.native, orElse: () => pay.first);
      }
      // Default the "get" side to the first token that isn't the "pay" token.
      for (final a in get) {
        if (a == from) continue;
        to = a;
        break;
      }

      if (!mounted) return;
      setState(() {
        _assets = pay;
        _getAssets = get;
        _fromAsset = from;
        _toAsset = to;
        _loadingAssets = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAssets = false;
        _assetsError = e.toString();
      });
    }
  }

  /// "You get" assets: every Uniswap token on the active chain, excluding whatever is
  /// selected on the "pay" side.
  List<ExchangeAsset> get _outAssets =>
      _getAssets.where((a) => a != _fromAsset).toList();

  /// An EVM token that at least one on-chain DEX provider (Uniswap or PancakeSwap) supports.
  static bool _isSwappableEvm(ExchangeAsset a) =>
      a.token.addrType == 1 &&
      a.providers.any((p) =>
          p.whenOrNull(uniswap: (_) => true, pancakeSwap: (_) => true) ?? false);

  /// `tokenOut` for the swap. Same-chain only, so it's just the token address; native
  /// tokens already carry the zero address in the catalog (the Rust layer substitutes
  /// WETH internally for native input/output).
  String _outTokenParam(ExchangeAsset to) => to.token.addr;

  void _scheduleQuote() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer(_quoteDebounce, _fetchQuotes);
  }

  Future<void> _fetchQuotes() async {
    final account = _appState.account;
    final from = _fromAsset;
    final to = _toAsset;
    if (account == null || from == null || to == null) return;

    final amountWei = toDecimalsWei(_amount, from.token.decimals);
    if (amountWei <= BigInt.zero) {
      setState(() {
        _quotes = const [];
        _selectedQuote = null;
      });
      return;
    }

    setState(() => _loadingQuote = true);

    try {
      final quotes = await fetchExchangeQuote(
        asset: from,
        fromAsset: from.token.addr,
        toAsset: _outTokenParam(to),
        amount: amountWei.toString(),
        destination: account.addr,
      );
      // Sort best (highest output) first; auto-select it. The user can override via the picker.
      quotes.sort((a, b) => (BigInt.tryParse(b.amountOut) ?? BigInt.zero)
          .compareTo(BigInt.tryParse(a.amountOut) ?? BigInt.zero));

      if (!mounted) return;
      setState(() {
        _quotes = quotes;
        _selectedQuote = quotes.isNotEmpty ? quotes.first : null;
        _loadingQuote = false;
      });
    } catch (e) {
      debugPrint("exchange quote failed: $e");
      if (!mounted) return;
      setState(() {
        _quotes = const [];
        _selectedQuote = null;
        _loadingQuote = false;
      });
    }
  }

  // --- input --------------------------------------------------------------

  void _onKeyPress(String value) {
    if (value == ".") {
      if (!_hasDecimalPoint) {
        setState(() {
          _hasDecimalPoint = true;
          _amount = _amount == "0" ? "0." : "$_amount.";
        });
        _scheduleQuote();
      }
      return;
    }

    setState(() {
      if (_hasDecimalPoint) {
        _amount += value;
      } else {
        _amount = _amount == "0" ? value : "$_amount$value";
      }
    });
    _scheduleQuote();
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length > 1) {
        if (_amount.endsWith('.')) _hasDecimalPoint = false;
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = "0";
        _hasDecimalPoint = false;
      }
    });
    _scheduleQuote();
  }

  void _selectFrom(ExchangeAsset asset) {
    setState(() {
      _fromAsset = asset;
      _amount = "0";
      _hasDecimalPoint = false;
      _quotes = const [];
      _selectedQuote = null;
      if (_toAsset == asset || _toAsset == null) {
        final outs = _outAssets;
        _toAsset = outs.isNotEmpty ? outs.first : null;
      }
    });
  }

  void _selectTo(ExchangeAsset asset) {
    setState(() {
      _toAsset = asset;
      _quotes = const [];
      _selectedQuote = null;
    });
    _scheduleQuote();
  }

  bool get _canSwap {
    final from = _fromAsset;
    if (from == null || _toAsset == null || _selectedQuote == null) {
      return false;
    }
    if (_amount.endsWith('.')) return false;
    final amountWei = toDecimalsWei(_amount, from.token.decimals);
    if (amountWei <= BigInt.zero) return false;
    final balance = BigInt.tryParse(
            from.token.balances[_appState.accountBalanceKey] ?? '') ??
        BigInt.zero;
    return amountWei <= balance;
  }

  // --- confirm ------------------------------------------------------------

  void _handleSwap() {
    if (!_canSwap) return;

    final appState = _appState;
    final wallet = appState.wallet;
    final account = appState.account;
    final from = _fromAsset;
    final to = _toAsset;
    final quote = _selectedQuote;
    if (wallet == null ||
        account == null ||
        from == null ||
        to == null ||
        quote == null) {
      return;
    }

    final isSupported = quote.provider.whenOrNull(
          uniswap: (_) => true,
          pancakeSwap: (_) => true,
        ) ??
        false;
    if (!isSupported) {
      _showError('Unsupported provider');
      return;
    }

    final fromToken = from.token;
    // Native tokens already carry the zero address; the Rust layer substitutes WETH
    // internally for native input (`isNativeIn`) and native output. Same-chain only.
    final tokenIn = fromToken.addr;
    final tokenOut = _outTokenParam(to);
    final amountInWei = toDecimalsWei(_amount, fromToken.decimals);

    // The confirm modal owns route selection and the whole approve → permit → swap sequence
    // (batched for software wallets, step-by-step on Ledger), so the page just hands it the
    // full quote list (best-first) and the shared swap intent.
    showExchangeConfirmModal(
      context: context,
      quotes: _quotes,
      fromToken: fromToken,
      toToken: to.token,
      amountInWei: amountInWei.toString(),
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      isNativeIn: fromToken.native,
      slippageBps: _slippageBps,
      onDone: () => context.go(AppRoutes.history),
      onDismiss: () => _btnController.reset(),
    );
  }

  void _showError(String message) {
    final theme = _appState.currentTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text(
          "Error",
          style: theme.titleMedium.copyWith(color: theme.textPrimary),
        ),
        content: Text(
          message,
          style: theme.bodyLarge.copyWith(color: theme.danger),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: theme.button.copyWith(color: theme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  // --- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = _appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final padding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildTabs(theme, l10n),
                ),
                Expanded(
                  child: _buildBody(theme, l10n, padding),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppTheme theme, AppLocalizations l10n, double padding) {
    final from = _fromAsset;
    final to = _toAsset;

    // Only show a message once bootstrap finished with nothing to swap.
    if (!_loadingAssets &&
        (_assetsError != null || from == null || to == null)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            _assetsError ?? l10n.exchangePageNoAssets,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(color: theme.textSecondary),
          ),
        ),
      );
    }

    // Bootstrap is fast — don't flash any loading state. Render nothing until the
    // assets land, then show the real cards.
    if (from == null || to == null) {
      return const SizedBox.shrink();
    }

    final Widget cards = Column(
      children: [
        _buildPayCard(from),
        _buildDirectionButton(theme, from),
        _buildGetCard(theme, l10n, to),
      ],
    );

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        overscroll: true,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            children: [
              const SizedBox(height: 16),
              cards,
              const SizedBox(height: 8),
              NumberKeyboard(
                onKeyPressed: (value) => _onKeyPress(value.toString()),
                onBackspace: _onBackspace,
                onDotPress: () => _onKeyPress("."),
              ),
              RoundedLoadingButton(
                controller: _btnController,
                onPressed: !_canSwap ? null : _handleSwap,
                color: theme.primaryPurple,
                valueColor: theme.buttonText,
                child: Text(
                  l10n.exchangePageConfirm,
                  style: theme.titleMedium.copyWith(color: theme.buttonText),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(AppTheme theme, AppLocalizations l10n) {
    Widget tab(String label, _OrderType type, bool enabled) {
      final selected = _orderType == type;
      return GestureDetector(
        onTap: enabled ? () => setState(() => _orderType = type) : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Text(
            label,
            style: theme.titleSmall.copyWith(
              color: selected
                  ? theme.textPrimary
                  : theme.textSecondary.withValues(alpha: enabled ? 1.0 : 0.5),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          tab(l10n.exchangePageTabSwap, _OrderType.swap, true),
          tab(l10n.exchangePageTabLimit, _OrderType.limit, false),
          tab(l10n.exchangePageTabBuySell, _OrderType.buySell, false),
          const Spacer(),
          GestureDetector(
            onTap: () => showSwapSettingsModal(context: context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                "assets/icons/gear.svg",
                width: 22,
                height: 22,
                colorFilter:
                    ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayCard(ExchangeAsset from) {
    final token = from.token;
    final balance =
        BigInt.tryParse(token.balances[_appState.accountBalanceKey] ?? '') ??
            BigInt.zero;

    return TokenAmountCard(
      amount: _amount,
      token: token,
      balance: balance,
      onAmountChanged: (v) {
        setState(() {
          _amount = v;
          _hasDecimalPoint = v.contains('.');
        });
        _scheduleQuote();
      },
      onTokenTap: () => showExchangeTokenSelectModal(
        context: context,
        assets: _assets,
        onSelected: _selectFrom,
      ),
    );
  }

  Widget _buildDirectionButton(AppTheme theme, ExchangeAsset? from) {
    // Same-chain swaps are always reversible: the Rust backend handles native input
    // (WRAP_ETH) and native output (UNWRAP_WETH), so either token can be the input.
    final canFlip = from != null && _toAsset != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: canFlip
            ? () {
                final to = _toAsset;
                if (to == null) return;
                setState(() {
                  _fromAsset = to;
                  _toAsset = from;
                  _amount = "0";
                  _hasDecimalPoint = false;
                  _quotes = const [];
                  _selectedQuote = null;
                });
              }
            : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: SvgPicture.asset(
              "assets/icons/swap.svg",
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                canFlip
                    ? theme.primaryPurple
                    : theme.textSecondary.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGetCard(
      AppTheme theme, AppLocalizations l10n, ExchangeAsset to) {
    final token = to.token;
    final quote = _selectedQuote;
    final (outAmount, _) = quote == null
        ? ("0", "")
        : formatingAmount(
            amount: BigInt.tryParse(quote.amountOut) ?? BigInt.zero,
            symbol: token.symbol,
            decimals: token.decimals,
            rate: token.rate,
            appState: _appState,
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.exchangePageGet,
            style: theme.bodyText2.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  child: (quote == null && _loadingQuote)
                      ? SkeletonBox(
                          key: const ValueKey('get-skeleton'),
                          width: 150,
                          height: AdaptiveSize.getAdaptiveFontSize(context, 28),
                        )
                      : Text(
                          outAmount,
                          key: const ValueKey('get-value'),
                          style: theme.displayLarge.copyWith(
                            color: theme.textPrimary,
                            fontSize:
                                AdaptiveSize.getAdaptiveFontSize(context, 28),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
              _buildTokenSelector(
                theme,
                token,
                () => showExchangeTokenSelectModal(
                  context: context,
                  assets: _outAssets,
                  onSelected: _selectTo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenSelector(
    AppTheme theme,
    FTokenInfo token,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTokenAvatar(theme, token),
            const SizedBox(width: 8),
            Text(
              token.symbol,
              style: theme.bodyText1.copyWith(color: theme.textPrimary),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              "assets/icons/tiny_down_arrow.svg",
              width: 12,
              height: 12,
              colorFilter:
                  ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenAvatar(AppTheme theme, FTokenInfo token) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: AsyncImage(
          url: processTokenLogo(
            token: token,
            shortName: _appState.chain?.shortName ?? "",
            theme: theme.value,
          ),
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorWidget: Jazzicon(seed: token.addr, diameter: 24),
          loadingWidget: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
