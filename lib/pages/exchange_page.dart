import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/input_amount.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/number_keyboard.dart';
import 'package:bearby/components/skeleton_box.dart';
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

enum _OrderType { swap, buySell }

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage>
    with StatusBarMixin, TickerProviderStateMixin {
  static const Duration _quoteDebounce = Duration(milliseconds: 400);
  static const double _radialSize = 40;

  late final AppState _appState;
  late final ExchangeState _exchangeState;
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  late final AnimationController _countdownAnim;
  Timer? _quoteTimer;

  _OrderType _orderType = _OrderType.swap;
  String _amount = '0';
  bool _hasDecimalPoint = false;
  BigInt? _lastChainHash;
  BigInt? _lastAccount;
  String? _recipientOverride;
  bool _wasLoadingQuote = false;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _exchangeState = context.read<ExchangeState>();
    _lastChainHash = _appState.wallet?.chainHash;
    _lastAccount = _appState.wallet?.selectedAccount;
    _countdownAnim = AnimationController(
      vsync: this,
      duration: ExchangeState.pollInterval,
    );
    _appState.addListener(_onAppStateChanged);
    _exchangeState.addListener(_onExchangeStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _exchangeState.removeListener(_onExchangeStateChanged);
    _quoteTimer?.cancel();
    _countdownAnim.dispose();
    _btnController.dispose();
    super.dispose();
  }

  void _onExchangeStateChanged() {
    final loading = _exchangeState.loadingQuote;
    if (_wasLoadingQuote && !loading) {
      _countdownAnim.forward(from: 0.0);
    }
    _wasLoadingQuote = loading;
  }

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
    return ExchangeAsset(token: token, providers: const {}, halted: false);
  }

  Future<void> _bootstrap({ExchangeAsset? initialFrom}) {
    final walletIndex = _appState.selectedWalletIndexOrNull;
    if (walletIndex == null) return Future.value();
    return _exchangeState.bootstrap(
      walletIndex: walletIndex,
      accountIndex: _appState.wallet?.selectedAccount ?? BigInt.zero,
      activeChainHash: _appState.wallet?.chainHash,
      initialFrom: initialFrom ?? _nativeInitialAsset(),
    );
  }

  List<ExchangeAsset> _outAssets(ExchangeState state) {
    final from = state.fromAsset;
    return state.getAssets.where((asset) {
      if (asset == from) return false;
      if (from == null) return true;
      if (asset.token.chainHash == from.token.chainHash) return true;
      return _hasRelay(from) && _hasRelay(asset);
    }).toList();
  }

  static bool _hasRelay(ExchangeAsset asset) =>
      asset.providers.any((p) => p.whenOrNull(relay: (_) => true) ?? false);

  void _scheduleQuote() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer(_quoteDebounce, () {
      final from = _exchangeState.fromAsset;
      if (from == null || _amount.endsWith('.')) return;
      final amountWei = toDecimalsWei(_amount, from.token.decimals);
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
    if (_exchangeState.toAsset == asset || _exchangeState.toAsset == null) {
      final outs = _outAssets(_exchangeState);
      if (outs.isNotEmpty) _exchangeState.selectTo(outs.first);
    }
  }

  void _selectTo(ExchangeAsset asset) {
    setState(() => _recipientOverride = null);
    _exchangeState.selectTo(asset);
    _scheduleQuote();
  }

  bool _canSwap(ExchangeState state) {
    final from = state.fromAsset;
    if (from == null ||
        state.toAsset == null ||
        state.selectedProvider == null) {
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

  void _handleSwap(ExchangeState state) {
    if (!_canSwap(state)) return;
    final from = state.fromAsset;
    final to = state.toAsset;
    final provider = state.selectedProvider;
    if (from == null || to == null || provider == null) return;

    final supported = provider.whenOrNull(
          relay: (_) => true,
          uniswap: (_) => true,
          pancakeSwap: (_) => true,
        ) ??
        false;
    if (!supported) {
      _showError('Unsupported provider');
      return;
    }

    final defaultRecipient = provider.common.accountAddr;
    final destination = _recipientOverride ?? defaultRecipient;

    showExchangeConfirmModal(
      context: context,
      from: from,
      to: to,
      amountInWei: toDecimalsWei(_amount, from.token.decimals).toString(),
      destination: destination,
      slippageBps: state.slippageFor(provider),
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
        title: Text('Error',
            style: theme.titleMedium.copyWith(color: theme.textPrimary)),
        content:
            Text(message, style: theme.bodyLarge.copyWith(color: theme.danger)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: theme.button.copyWith(color: theme.primaryPurple)),
          ),
        ],
      ),
    );
  }

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
            child: Consumer<ExchangeState>(
              builder: (context, exchange, _) => Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildTabs(theme, l10n, exchange),
                  ),
                  Expanded(child: _buildBody(theme, l10n, padding, exchange)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppTheme theme, AppLocalizations l10n, double padding,
      ExchangeState state) {
    final from = state.fromAsset;
    final to = state.toAsset;
    if (!state.loadingAssets &&
        (state.assetsError != null || from == null || to == null)) {
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
              _buildPayCard(from, state),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.selectedProvider != null)
                      _buildCountdownRadial(theme)
                    else
                      const SizedBox(width: _radialSize),
                    _buildDirectionIcon(theme, from, state),
                  ],
                ),
              ),
              if (to == null)
                const SizedBox(height: 120)
              else
                _buildGetCard(theme, l10n, to, state),
              const SizedBox(height: 8),
              NumberKeyboard(
                onKeyPressed: (value) => _onKeyPress(value.toString()),
                onBackspace: _onBackspace,
                onDotPress: () => _onKeyPress('.'),
              ),
              RoundedLoadingButton(
                controller: _btnController,
                onPressed: !_canSwap(state) ? null : () => _handleSwap(state),
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

  Widget _buildTabs(
      AppTheme theme, AppLocalizations l10n, ExchangeState state) {
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
          tab(l10n.exchangePageTabBuySell, _OrderType.buySell, false),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final provider = state.selectedProvider;
              if (provider == null) return;
              showSwapSettingsModal(
                context: context,
                activeProvider: provider,
                exchangeState: state,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/icons/gear.svg',
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

  Widget _buildPayCard(ExchangeAsset from, ExchangeState state) {
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
        assets: state.payAssets,
        onSelected: _selectFrom,
      ),
    );
  }

  Widget _buildCountdownRadial(AppTheme theme) {
    return AnimatedBuilder(
      animation: _countdownAnim,
      builder: (_, __) {
        final progress = 1.0 - _countdownAnim.value;
        final seconds =
            (progress * ExchangeState.pollInterval.inSeconds).ceil();
        return SizedBox(
          width: _radialSize,
          height: _radialSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: _radialSize,
                height: _radialSize,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: theme.primaryPurple,
                  backgroundColor: theme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              Text(
                '$seconds',
                style: theme.bodyText1.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectionIcon(
      AppTheme theme, ExchangeAsset? from, ExchangeState state) {
    final canFlip = from != null && state.toAsset != null;
    return GestureDetector(
      onTap: canFlip
          ? () {
              final to = state.toAsset;
              if (to == null) return;
              setState(() {
                _amount = '0';
                _hasDecimalPoint = false;
                _recipientOverride = null;
              });
              state.selectFrom(to);
              state.selectTo(from);
            }
          : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/swap.svg',
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

  Widget _buildGetCard(AppTheme theme, AppLocalizations l10n, ExchangeAsset to,
      ExchangeState state) {
    final token = to.token;
    final quote = state.selectedProvider?.quote;
    final from = state.fromAsset;
    final rateLabel =
        quote == null || from == null ? null : _rateLabel(from, to, quote);
    final recipient = to.providers.firstOrNull?.common.accountAddr ?? '';
    final effectiveRecipient = _recipientOverride ?? recipient;
    final (outAmount, _) = quote == null
        ? ('0', '')
        : formatingAmount(
            amount: BigInt.tryParse(quote.amountOut) ?? BigInt.zero,
            symbol: '',
            decimals: token.decimals,
            rate: token.rate,
            appState: _appState,
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
            color: theme.textSecondary.withValues(alpha: 0.15), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecipientButton(theme, l10n, effectiveRecipient, to),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AdaptiveSize.getAdaptiveFontSize(context, 36),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild
                      ],
                    ),
                    child: (quote == null && state.loadingQuote)
                        ? SkeletonBox(
                            key: const ValueKey('get-skeleton'),
                            width: 150,
                            height:
                                AdaptiveSize.getAdaptiveFontSize(context, 28),
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              outAmount,
                              key: const ValueKey('get-value'),
                              style: theme.displayLarge.copyWith(
                                color: theme.textPrimary,
                                fontSize:
                                    AdaptiveSize.getAdaptiveFontSize(
                                        context, 28),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  assets: _outAssets(state),
                  onSelected: _selectTo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rateLabel ?? '-',
            style: theme.bodyText2.copyWith(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientButton(
    AppTheme theme,
    AppLocalizations l10n,
    String address,
    ExchangeAsset to,
  ) {
    return GestureDetector(
      onTap: () {
        final chainHash = to.providers.firstOrNull?.common.chainHash;
        showAddressSelectModal(
          context: context,
          chainHash: chainHash,
          title: l10n.exchangePageRecipientTitle,
          onAddressSelected: (info, _) {
            setState(() => _recipientOverride = info.recipient);
            Navigator.of(context, rootNavigator: true).pop();
          },
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Text(
        shortenAddress(address),
        style: theme.bodyText2.copyWith(
          color: theme.primaryPurple,
          decoration: TextDecoration.underline,
          decorationColor: theme.primaryPurple,
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
            SvgPicture.asset(
              'assets/icons/tiny_down_arrow.svg',
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
}

