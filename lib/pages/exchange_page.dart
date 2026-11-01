import 'package:bearby/components/app_icon.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/input_amount.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/number_keyboard.dart';
import 'package:bearby/components/shimmer_text.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/exchange_confirm.dart';
import 'package:bearby/modals/select_address.dart';
import 'package:bearby/modals/select_exchange_token.dart';
import 'package:bearby/modals/swap_settings.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/state/exchange_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

/// Why the Swap button is disabled; `null` means the swap is ready.
enum _SwapBlocker {
  selectToken,
  enterAmount,
  insufficientBalance,
  loading,
  noRoute,
}

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> with StatusBarMixin {
  static const Duration _quoteDebounce = Duration(milliseconds: 400);

  late final AppState _appState;
  late final ExchangeState _exchangeState;
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  Timer? _quoteTimer;

  String _amount = '0';
  bool _hasDecimalPoint = false;
  BigInt? _lastChainHash;
  BigInt? _lastAccount;
  String? _recipientOverride;
  bool _firstFrameDone = false;
  bool _wasVisible = false;
  double _flipTurns = 0;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _exchangeState = context.read<ExchangeState>();
    _lastChainHash = _appState.wallet?.chainHash;
    _lastAccount = _appState.wallet?.selectedAccount;
    _appState.addListener(_onAppStateChanged);
    _exchangeState.addListener(_onExchangeStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFrameDone = true;
      _bootstrap();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // go_router keeps this branch alive in an IndexedStack and only toggles
    // TickerMode when the tab becomes (in)active. Use that flip to re-fetch
    // balances/assets on re-entry — initState runs only on the first visit.
    final isVisible = TickerMode.valuesOf(context).enabled;
    if (isVisible && !_wasVisible && _firstFrameDone) {
      // Defer: didChangeDependencies runs during build, but _bootstrap calls
      // notifyListeners() which would mark the provider dirty mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bootstrap(initialFrom: _exchangeState.fromAsset);
      });
    } else if (!isVisible && _wasVisible) {
      // Page is leaving the viewport: stop the 10s quote poll timer. The
      // rising edge above re-bootstraps on re-entry, which restarts polling.
      _exchangeState.pause();
    }
    _wasVisible = isVisible;
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _exchangeState.removeListener(_onExchangeStateChanged);
    _quoteTimer?.cancel();
    _btnController.dispose();
    super.dispose();
  }

  void _onExchangeStateChanged() {}

  void _onAppStateChanged() {
    final hash = _appState.wallet?.chainHash;
    final account = _appState.wallet?.selectedAccount;
    if (hash == _lastChainHash && account == _lastAccount) return;
    _lastChainHash = hash;
    _lastAccount = account;
    _quoteTimer?.cancel();
    setState(() {
      _amount = '0';
      _hasDecimalPoint = false;
      _recipientOverride = null;
    });
    _bootstrap(initialFrom: _exchangeState.fromAsset);
  }

  ExchangeAsset? _nativeInitialAsset() {
    final chainHash = _appState.wallet?.chainHash;
    final token = _appState.wallet?.tokens
        .where((t) => t.chainHash == chainHash && t.native)
        .firstOrNull;
    if (token == null) return null;
    return ExchangeAsset(token: token, providers: const [], halted: false);
  }

  Future<void> _bootstrap({ExchangeAsset? initialFrom}) {
    final walletIndex = _appState.selectedWalletIndexOrNull;
    if (walletIndex == null) return Future.value();
    return _exchangeState.bootstrap(
      walletIndex: walletIndex,
      accountIndex: _appState.wallet?.selectedAccount ?? BigInt.zero,
      activeChainHash: _appState.wallet?.chainHash,
      balanceKey: _appState.accountBalanceKey,
      initialFrom: initialFrom ?? _nativeInitialAsset(),
    );
  }

  void _scheduleQuote() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer(_quoteDebounce, () {
      final from = _exchangeState.fromAsset;
      final to = _exchangeState.toAsset;
      if (from == null || _amount.endsWith('.')) return;
      final amountWei = toDecimalsWei(_amount, from.token.decimals);
      debugPrint(
        '[ExchangePage] scheduleQuote from=${from.token.symbol} '
        'to=${to?.token.symbol} amount=$_amount amountWei=$amountWei '
        'fromProviders=${from.providers.length}',
      );
      _exchangeState.setAmount(amountWei.toString());
    });
  }

  void _onKeyPress(String value) {
    if (value == '.') {
      if (!_hasDecimalPoint) {
        setState(() {
          _hasDecimalPoint = true;
          _amount = _amount == '0' ? '0.' : '$_amount.';
        });
        _scheduleQuote();
      }
      return;
    }
    setState(() {
      _amount = _hasDecimalPoint
          ? '$_amount$value'
          : (_amount == '0' ? value : '$_amount$value');
    });
    _scheduleQuote();
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length > 1) {
        if (_amount.endsWith('.')) _hasDecimalPoint = false;
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
        _hasDecimalPoint = false;
      }
    });
    _scheduleQuote();
  }

  void _selectFrom(ExchangeAsset asset) {
    setState(() {
      _amount = '0';
      _hasDecimalPoint = false;
      _recipientOverride = null;
    });
    _exchangeState.selectFrom(asset);
    final to = _exchangeState.toAsset;
    if (to == null) return;

    final outs = _exchangeState.outAssets;
    if (to == asset || !outs.contains(to)) {
      _exchangeState.clearTo();
    }
  }

  void _selectTo(ExchangeAsset asset) {
    setState(() => _recipientOverride = null);
    _exchangeState.selectTo(asset);
    _scheduleQuote();
  }

  BigInt _balanceOf(ExchangeAsset asset) =>
      BigInt.tryParse(
          asset.token.balances[_appState.accountBalanceKey] ?? '') ??
      BigInt.zero;

  _SwapBlocker? _swapBlocker(ExchangeState state) {
    final from = state.fromAsset;
    if (from == null || state.toAsset == null) return _SwapBlocker.selectToken;
    if (_amount.endsWith('.')) return _SwapBlocker.enterAmount;
    final amountWei = toDecimalsWei(_amount, from.token.decimals);
    if (amountWei <= BigInt.zero) return _SwapBlocker.enterAmount;
    if (amountWei > _balanceOf(from)) return _SwapBlocker.insufficientBalance;
    if (state.selectedProvider == null) {
      return state.quoteStatus == QuoteStatus.noRoute
          ? _SwapBlocker.noRoute
          : _SwapBlocker.loading;
    }
    return null;
  }

  String _swapLabel(
      AppLocalizations l10n, _SwapBlocker? blocker, ExchangeAsset? from) {
    return switch (blocker) {
      null => l10n.exchangePageConfirm,
      _SwapBlocker.selectToken => l10n.exchangePageSelectToken,
      _SwapBlocker.enterAmount => l10n.exchangePageEnterAmount,
      _SwapBlocker.insufficientBalance =>
        l10n.exchangePageInsufficientBalance(from?.token.symbol ?? ''),
      _SwapBlocker.loading => l10n.exchangePageFindingRoute,
      _SwapBlocker.noRoute => l10n.exchangePageNoRoute,
    };
  }

  void _openSettings(ExchangeState state) {
    final provider = state.selectedProvider;
    if (provider == null) return;
    showSwapSettingsModal(
      context: context,
      activeProvider: provider,
      exchangeState: state,
    );
  }

  void _flip(ExchangeState state) {
    final from = state.fromAsset;
    final to = state.toAsset;
    if (from == null || to == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _flipTurns += 0.5;
      _amount = '0';
      _hasDecimalPoint = false;
      _recipientOverride = null;
    });
    state.selectFrom(to);
    state.selectTo(from);
  }

  void _handleSwap(ExchangeState state) {
    if (_swapBlocker(state) != null) return;
    final from = state.fromAsset;
    final to = state.toAsset;
    final provider = state.selectedProvider;
    if (from == null || to == null || provider == null) return;

    final override = _recipientOverride;
    final destination = provider.supportsCustomRecipient && override != null
        ? override
        : provider.common.accountAddr;

    showExchangeConfirmModal(
      context: context,
      from: from,
      to: to,
      amountInWei: toDecimalsWei(_amount, from.token.decimals).toString(),
      destination: destination,
      slippageBps: state.slippageFor(provider),
      onDone: () {
        _btnController.reset();
        if (mounted) context.go(AppRoutes.history);
      },
      onDismiss: () => _btnController.reset(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final padding = AdaptiveSize.getAdaptivePadding(context, 16);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 960;
    final isDesktop = screenWidth >= 960;
    final double maxWidth = isDesktop
        ? 920.0
        : isTablet
            ? 760.0
            : 480.0;

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
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Consumer<ExchangeState>(
              builder: (context, exchange, _) =>
                  _buildBody(theme, l10n, padding, exchange, screenWidth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AppTheme theme,
    AppLocalizations l10n,
    double padding,
    ExchangeState state,
    double screenWidth,
  ) {
    final from = state.fromAsset;
    final to = state.toAsset;
    if (!state.loadingAssets && (state.assetsError != null || from == null)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            state.assetsError ?? l10n.exchangePageNoAssets,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(color: theme.textSecondary),
          ),
        ),
      );
    }
    if (from == null) return const Center(child: CircularProgressIndicator());

    final isTwoColumn = screenWidth >= 720;

    final cardsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionLabel(theme, l10n.exchangePagePay),
        _buildPayCard(theme, from),
        _buildFlipRow(theme, l10n, state),
        if (to == null)
          _buildEmptyGetCard(theme, l10n, state)
        else
          _buildGetCard(theme, l10n, to, state),
      ],
    );

    final keypadColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NumberKeyboard(
          onKeyPressed: (value) => _onKeyPress(value.toString()),
          onBackspace: _onBackspace,
          onDotPress: () => _onKeyPress('.'),
        ),
        const SizedBox(height: 8),
        _buildSwapButton(theme, l10n, state),
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
          child: isTwoColumn
              ? Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: cardsColumn,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 9,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            decoration: BoxDecoration(
                              color: theme.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    theme.textPrimary.withValues(alpha: 0.08),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: keypadColumn,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    cardsColumn,
                    const SizedBox(height: 8),
                    keypadColumn,
                    const SizedBox(height: 28),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(AppTheme theme, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          label,
          style: theme.bodyText2.copyWith(
            color: theme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(AppTheme theme) => BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(theme.cardBackground, theme.primaryPurple, 0.05)!,
            theme.cardBackground,
          ],
        ),
      );

  /// Matches the outline [TokenAmountCard] draws for itself on the pay side.
  BoxDecoration _getCardDecoration(AppTheme theme) =>
      _cardDecoration(theme).copyWith(
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.08),
          width: 1.2,
        ),
      );

  Widget _buildPayCard(AppTheme theme, ExchangeAsset from) {
    return DecoratedBox(
      decoration: _cardDecoration(theme),
      child: TokenAmountCard(
        amount: _amount,
        token: from.token,
        balance: _balanceOf(from),
        onAmountChanged: (v) {
          setState(() {
            _amount = v;
            _hasDecimalPoint = v.contains('.');
          });
          _scheduleQuote();
        },
        onTokenTap: () => showExchangeTokenSelectModal(
          context: context,
          assetSelector: (s) => s.payAssets,
          onSelected: _selectFrom,
        ),
      ),
    );
  }

  /// "You get" label on the left with the flip button centered between the two cards.
  Widget _buildFlipRow(
      AppTheme theme, AppLocalizations l10n, ExchangeState state) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: _buildSectionLabel(theme, l10n.exchangePageGet),
          ),
          _buildDirectionIcon(theme, state),
        ],
      ),
    );
  }

  Widget _buildDirectionIcon(AppTheme theme, ExchangeState state) {
    final canFlip = state.fromAsset != null && state.toAsset != null;
    return GestureDetector(
      onTap: canFlip ? () => _flip(state) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: canFlip
              ? theme.primaryPurple.withValues(alpha: 0.12)
              : theme.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: canFlip
                ? theme.primaryPurple.withValues(alpha: 0.35)
                : theme.textSecondary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Center(
          child: AnimatedRotation(
            turns: _flipTurns,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AppIconView(
              icon: AppIcon.swap,
              size: 20,
              color: canFlip
                  ? theme.primaryPurple
                  : theme.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  String? _rateLabel(
      ExchangeAsset from, ExchangeAsset to, ProviderQuote quote) {
    final amountInWei = toDecimalsWei(_amount, from.token.decimals);
    if (amountInWei <= BigInt.zero) return null;
    final amountOutWei = BigInt.tryParse(quote.amountOut) ?? BigInt.zero;
    if (amountOutWei == BigInt.zero) return null;
    final oneFromWei = BigInt.from(10).pow(from.token.decimals);
    final rateOutWei = (amountOutWei * oneFromWei) ~/ amountInWei;
    final (rateAmount, _) = formatingAmount(
      amount: rateOutWei,
      symbol: '',
      decimals: to.token.decimals,
      rate: to.token.rate,
      appState: _appState,
    );
    return '1 ${from.token.symbol} ≈ $rateAmount ${to.token.symbol}';
  }

  Widget _buildEmptyGetCard(
      AppTheme theme, AppLocalizations l10n, ExchangeState state) {
    final outs = state.outAssets;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(theme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildEmptyTokenSelector(
            theme,
            l10n,
            outs.isNotEmpty
                ? () => showExchangeTokenSelectModal(
                      context: context,
                      assetSelector: (s) => s.outAssets,
                      onSelected: _selectTo,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGetCard(AppTheme theme, AppLocalizations l10n, ExchangeAsset to,
      ExchangeState state) {
    final token = to.token;
    final selectedProvider = state.selectedProvider;
    final quote = selectedProvider?.quote;
    final from = state.fromAsset;
    final recipient = to.providers.firstOrNull?.common.accountAddr ?? '';
    // Use the selected (best-quoted) provider when available. If no quote has
    // landed yet, fall back to inspecting every provider that can route this
    // pair: if any of them disallows custom recipient (e.g. PlunderSwap /
    // ZilSwap), disable the button so the user can't pick an address that
    // would be silently ignored.
    final allowCustomRecipient = selectedProvider != null
        ? selectedProvider.supportsCustomRecipient
        : to.providers.isNotEmpty &&
            to.providers.every((p) => p.supportsCustomRecipient);
    final effectiveRecipient =
        allowCustomRecipient ? (_recipientOverride ?? recipient) : recipient;
    final (outAmount, _) = quote == null
        ? ('0', '')
        : formatingAmount(
            amount: BigInt.tryParse(quote.amountOut) ?? BigInt.zero,
            symbol: '',
            decimals: token.decimals,
            rate: token.rate,
            appState: _appState,
          );
    final status = state.quoteStatus;
    final amountInWei = from == null
        ? BigInt.zero
        : toDecimalsWei(_amount, from.token.decimals);
    final showAmountShimmer =
        status == QuoteStatus.loading && amountInWei > BigInt.zero;
    final outAmountStyle = theme.displayLarge.copyWith(
      color: theme.textPrimary,
      fontSize: 28,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(theme),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecipientButton(
              theme,
              l10n,
              effectiveRecipient,
              to,
              allowCustomRecipient,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: AlignmentDirectional.centerStart,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild
                        ],
                      ),
                      child: Align(
                        key: showAmountShimmer
                            ? const ValueKey<String>('get-shimmer')
                            : const ValueKey<String>('get-value'),
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: showAmountShimmer
                              ? ShimmerText(
                                  text: outAmount,
                                  style: outAmountStyle,
                                  baseColor:
                                      theme.textPrimary.withValues(alpha: 0.35),
                                  highlightColor: theme.textPrimary,
                                )
                              : Text(
                                  outAmount,
                                  style: outAmountStyle,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildTokenSelector(
                  theme,
                  token,
                  () => showExchangeTokenSelectModal(
                    context: context,
                    assetSelector: (s) => s.outAssets,
                    onSelected: _selectTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildQuoteInfo(theme, l10n, state, to),
          ],
        ),
      ),
    );
  }

  /// Rate + route/slippage once quoted; otherwise a plain-language status line.
  Widget _buildQuoteInfo(AppTheme theme, AppLocalizations l10n,
      ExchangeState state, ExchangeAsset to) {
    final provider = state.selectedProvider;
    final quote = provider?.quote;
    final from = state.fromAsset;
    final secondary = theme.bodyText2.copyWith(color: theme.textSecondary);
    if (provider == null || quote == null || from == null) {
      final (text, color) = switch (state.quoteStatus) {
        QuoteStatus.loading => (
            l10n.exchangePageFindingRoute,
            theme.textSecondary
          ),
        QuoteStatus.noRoute => (l10n.exchangePageNoRoute, theme.warning),
        QuoteStatus.idle || QuoteStatus.ready => ('-', theme.textSecondary),
      };
      return Text(text, style: secondary.copyWith(color: color));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_rateLabel(from, to, quote) ?? '-', style: secondary),
        const SizedBox(height: 6),
        _buildRouteRow(theme, l10n, state, provider),
      ],
    );
  }

  /// "via Uniswap · 0.5% slippage" — tap opens swap settings.
  Widget _buildRouteRow(AppTheme theme, AppLocalizations l10n,
      ExchangeState state, ExchangeProvider provider) {
    final slippage = (state.slippageFor(provider) / 100).toStringAsFixed(1);
    return GestureDetector(
      onTap: () => _openSettings(state),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primaryPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              provider.common.iconAsset,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${l10n.exchangePageRouteVia(provider.common.displayName)}'
                ' · ${l10n.exchangePageSlippage(slippage)}',
                style: theme.bodyText2.copyWith(color: theme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            AppIconView(
              icon: AppIcon.settings,
              size: 14,
              color: theme.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapButton(
      AppTheme theme, AppLocalizations l10n, ExchangeState state) {
    final blocker = _swapBlocker(state);
    final ready = blocker == null;
    final isProblem = blocker == _SwapBlocker.insufficientBalance ||
        blocker == _SwapBlocker.noRoute;
    final label = _swapLabel(l10n, blocker, state.fromAsset);
    final textColor = ready
        ? theme.buttonText
        : isProblem
            ? theme.warning
            : theme.textSecondary.withValues(alpha: 0.7);
    return RoundedLoadingButton(
      controller: _btnController,
      onPressed: ready ? () => _handleSwap(state) : null,
      color: ready
          ? theme.primaryPurple
          : isProblem
              ? theme.warning.withValues(alpha: 0.15)
              : theme.textSecondary.withValues(alpha: 0.18),
      valueColor: theme.buttonText,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          label,
          key: ValueKey<String>(label),
          style: theme.titleMedium.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _buildRecipientButton(
    AppTheme theme,
    AppLocalizations l10n,
    String address,
    ExchangeAsset to,
    bool enabled,
  ) {
    final text = Text(
      shortenAddress(address),
      style: theme.bodyText2.copyWith(
        color: enabled
            ? theme.primaryPurple
            : theme.textSecondary.withValues(alpha: 0.7),
        decoration: enabled ? TextDecoration.underline : TextDecoration.none,
        decorationColor: theme.primaryPurple,
      ),
    );
    if (!enabled) return text;
    return GestureDetector(
      onTap: () {
        final chainHash = to.providers.firstOrNull?.common.chainHash;
        showAddressSelectModal(
          context: context,
          chainHash: chainHash,
          title: l10n.exchangePageRecipientTitle,
          onAddressSelected: (info, _) {
            setState(() => _recipientOverride = info.recipient);
          },
        );
      },
      behavior: HitTestBehavior.opaque,
      child: text,
    );
  }

  Widget _buildEmptyTokenSelector(
      AppTheme theme, AppLocalizations l10n, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? theme.primaryPurple
              : theme.textSecondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.exchangePageSelectToken,
              style: theme.bodyText1.copyWith(
                color: enabled
                    ? theme.buttonText
                    : theme.textSecondary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            AppIconView(
              icon: AppIcon.arrowDown,
              size: 12,
              color: enabled
                  ? theme.buttonText
                  : theme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSelector(
      AppTheme theme, FTokenInfo token, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.textPrimary.withValues(alpha: 0.2), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TokenAvatar(token: token, appState: _appState),
            const SizedBox(width: 8),
            Text(token.symbol,
                style: theme.bodyText1.copyWith(color: theme.textPrimary)),
            const SizedBox(width: 4),
            AppIconView(
              icon: AppIcon.arrowDown,
              size: 12,
              color: theme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
