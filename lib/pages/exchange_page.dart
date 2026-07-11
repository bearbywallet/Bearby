import 'package:bearby/components/app_icon.dart';
import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/exchange_confirm.dart';
import 'package:bearby/modals/select_address.dart';
import 'package:bearby/modals/select_exchange_token.dart';
import 'package:bearby/modals/swap_settings.dart';
import 'package:bearby/modals/transfer.dart';
import 'package:bearby/modals/whitebird_orders_modal.dart';
import 'package:bearby/pages/whitebird_sdk_page.dart';
import 'package:bearby/router.dart';
import 'package:bearby/services/whitebird_session.dart';
import 'package:bearby/src/rust/api/exchange/whitebird.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/exchange/whitebird.dart';
import 'package:bearby/src/rust/models/exchange/whitebird/orders.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/state/exchange_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

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
  List<WhiteBirdOpenOrder> _openOrders = const [];

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
    return ExchangeAsset(token: token, providers: const {}, halted: false);
  }

  Future<void> _bootstrap({ExchangeAsset? initialFrom}) {
    final walletIndex = _appState.selectedWalletIndexOrNull;
    if (walletIndex == null) return Future.value();
    unawaited(_refreshOpenOrders());
    return _exchangeState.bootstrap(
      walletIndex: walletIndex,
      accountIndex: _appState.wallet?.selectedAccount ?? BigInt.zero,
      activeChainHash: _appState.wallet?.chainHash,
      initialFrom: initialFrom ?? _nativeInitialAsset(),
    );
  }

  bool get _isTestnet => _appState.chain?.testnet ?? true;

  /// Open PROCESSING WhiteBird orders — fetched only when a session exists.
  /// Locally dismissed orders are hidden from the badge/modal unless
  /// [includeDismissed] — WhiteBird still counts them as the active order.
  Future<List<WhiteBirdOpenOrder>> _fetchOpenOrders(
      {bool includeDismissed = false}) async {
    final session = WhiteBirdSession(_appState.storage);
    await session.ensureLoaded();
    if (!session.hasSession) return const [];
    final externalId = await session.ensureExternalClientId();
    final orders = await whitebirdOpenOrders(
      isTestnet: _isTestnet,
      externalClientId: externalId,
      clientId: session.clientId,
    );
    final learnedClientId =
        orders.where((o) => o.clientId.isNotEmpty).firstOrNull?.clientId;
    if (learnedClientId != null) await session.saveClientId(learnedClientId);
    if (includeDismissed) return orders;
    final dismissed = session.dismissedOrderIds;
    return orders
        .where((o) => !dismissed.contains(o.orderId))
        .toList(growable: false);
  }

  Future<void> _refreshOpenOrders() async {
    try {
      final orders = await _fetchOpenOrders();
      if (mounted) setState(() => _openOrders = orders);
    } catch (e) {
      debugPrint('[ExchangePage] open orders fetch failed: $e');
    }
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
    // Fiat buy: the user pays off-wallet inside the WhiteBird SDK — no balance gate.
    if (_isFiatAsset(from)) return true;
    final balance = BigInt.tryParse(
            from.token.balances[_appState.accountBalanceKey] ?? '') ??
        BigInt.zero;
    return amountWei <= balance;
  }

  static bool _isFiatAsset(ExchangeAsset asset) =>
      asset.providers.any((p) => p.whiteBirdMeta?.isFiat ?? false);

  void _handleSwap(ExchangeState state) {
    if (!_canSwap(state)) return;
    final from = state.fromAsset;
    final to = state.toAsset;
    final provider = state.selectedProvider;
    if (from == null || to == null || provider == null) return;

    final wbMeta = provider.whiteBirdMeta;
    if (wbMeta != null) {
      unawaited(_handleWhiteBirdSwap(from, to, wbMeta));
      return;
    }

    final supported = provider.whenOrNull(
          relay: (_) => true,
          uniswap: (_) => true,
          pancakeSwap: (_) => true,
          plunderSwap: (_) => true,
          zilSwap: (_) => true,
          sunSwap: (_) => true,
        ) ??
        false;
    if (!supported) {
      _showError('Unsupported provider');
      return;
    }

    final defaultRecipient = provider.common.accountAddr;
    final destination = (provider.supportsCustomRecipient && _recipientOverride != null)
        ? _recipientOverride!
        : defaultRecipient;

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

  /// Fiat↔crypto order via the WhiteBird SDK.
  ///
  /// One webview covers everything: the session is created on the Bearby
  /// proxy first (no user tokens needed), then the SDK handles login/KYC if
  /// required and continues straight into the exchange. Sells intercept
  /// `onOrderCreated` to run the wallet transfer confirm on top of the SDK's
  /// deposit screen; buys complete fully inside the SDK.
  Future<void> _handleWhiteBirdSwap(
    ExchangeAsset from,
    ExchangeAsset to,
    WhiteBirdMeta fromMeta,
  ) async {
    try {
      final toMeta =
          to.providers.map((p) => p.whiteBirdMeta).nonNulls.firstOrNull;
      if (toMeta == null) {
        _showError('WhiteBird route is missing on the target asset');
        return;
      }

      final session = WhiteBirdSession(_appState.storage);
      await session.ensureLoaded();
      final externalId = await session.ensureExternalClientId();

      // A sell still waiting for its deposit blocks a new order — WhiteBird
      // keeps one active order per client and the SDK resumes it (without
      // firing onOrderCreated) instead of creating a fresh one. Route the
      // user to the open-orders modal to finish it; local dismissal cannot
      // unblock this, so check the unfiltered list.
      final open = await _fetchOpenOrders(includeDismissed: true);
      final awaitingDeposit = open
          .where((o) =>
              o.isSell &&
              !o.cryptoReceived &&
              (o.depositAddress?.isNotEmpty ?? false))
          .toList(growable: false);
      if (awaitingDeposit.isNotEmpty) {
        if (mounted) _showOrdersModal(awaitingDeposit);
        return;
      }

      final isSell = !fromMeta.isFiat;
      final cryptoMeta = isSell ? fromMeta : toMeta;
      final amountHuman = _amount;
      final info = await whitebirdCreateSession(
        isTestnet: _isTestnet,
        fromCode: fromMeta.assetCode,
        toCode: toMeta.assetCode,
        fromAmount: amountHuman,
        destinationCryptoAddress: cryptoMeta.common.accountAddr,
        externalClientId: externalId,
      );
      if (!mounted) return;

      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => WhiteBirdSdkPage(
            isTestnet: _isTestnet,
            externalClientId: externalId,
            clientId: session.clientId,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            sessionId: info.sessionId,
            currencyFrom: fromMeta.assetCode,
            currencyTo: toMeta.assetCode,
            currencyAmount: amountHuman,
            cryptoWallet: isSell ? null : cryptoMeta.common.accountAddr,
            // The order's own asset/amount win: WhiteBird may have resumed an
            // older active order whose values differ from the typed ones.
            onDepositReady: isSell
                ? (deposit) => _confirmDepositTransfer(
                      (deposit.fromAsset.isNotEmpty
                              ? _assetForWbCode(deposit.fromAsset)
                              : null) ??
                          from,
                      deposit.amountHuman.isNotEmpty
                          ? deposit.amountHuman
                          : amountHuman,
                      deposit.depositAddress,
                    )
                : null,
          ),
        ),
      );

      unawaited(_refreshOpenOrders());
      if (done == true && mounted) context.go(AppRoutes.history);
    } catch (e) {
      debugPrint('[ExchangePage] whitebird swap failed: $e');
      if (mounted) _showError(e.toString());
    } finally {
      _btnController.reset();
    }
  }

  /// Wallet transfer confirm for a WhiteBird sell deposit. Returns `true`
  /// once the transaction is signed and broadcast.
  Future<bool> _confirmDepositTransfer(
    ExchangeAsset from,
    String amountHuman,
    String depositAddress,
  ) async {
    final wallet = _appState.wallet;
    if (wallet == null || depositAddress.isEmpty) return false;
    final token = from.token;
    final tx = await createTokenTransfer(
      params: TokenTransferParamsInfo(
        walletIndex: _appState.selectedWalletIndex,
        accountIndex: wallet.selectedAccount,
        token: token,
        amount: toDecimalsWei(amountHuman, token.decimals).toString(),
        recipient: depositAddress,
        icon: processTokenLogo(
          token: token,
          shortName: _appState.chain?.shortName ?? '',
          theme: _appState.currentTheme.value,
        ),
      ),
    );
    if (!mounted) return false;

    final completer = Completer<bool>();
    showConfirmTransactionModal(
      context: context,
      tx: tx,
      to: depositAddress,
      amount: amountHuman,
      token: token,
      onConfirm: (_) {
        if (!completer.isCompleted) completer.complete(true);
      },
      onDismiss: () {
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return completer.future;
  }

  ExchangeAsset? _assetForWbCode(String code) {
    for (final asset in _exchangeState.payAssets) {
      final meta =
          asset.providers.map((p) => p.whiteBirdMeta).nonNulls.firstOrNull;
      if (meta != null && !meta.isFiat && meta.assetCode == code) return asset;
    }
    return null;
  }

  /// "Complete" action from the open-orders modal: send the crypto the order
  /// is still waiting for, then jump to history.
  Future<bool> _completeOpenOrder(WhiteBirdOpenOrder order) async {
    final l10n = AppLocalizations.of(context);
    final deposit = order.depositAddress;
    if (deposit == null || deposit.isEmpty) return false;
    final asset = _assetForWbCode(order.fromAsset);
    if (asset == null) {
      if (l10n != null) _showError(l10n.whitebirdOrdersWrongNetwork);
      return false;
    }
    try {
      final done =
          await _confirmDepositTransfer(asset, order.fromAmount, deposit);
      if (done) {
        unawaited(_refreshOpenOrders());
        if (mounted) context.go(AppRoutes.history);
      }
      return done;
    } catch (e) {
      debugPrint('[ExchangePage] complete order failed: $e');
      if (mounted) _showError(e.toString());
      return false;
    }
  }

  /// Close an order card locally: WhiteBird has no cancel API, the order
  /// simply expires server-side — we stop showing it.
  Future<List<WhiteBirdOpenOrder>> _dismissOpenOrder(
      WhiteBirdOpenOrder order) async {
    final session = WhiteBirdSession(_appState.storage);
    await session.dismissOrder(order.orderId);
    final orders = await _fetchOpenOrders();
    if (mounted) setState(() => _openOrders = orders);
    return orders;
  }

  void _showOrdersModal([List<WhiteBirdOpenOrder>? orders]) {
    final items = orders ?? _openOrders;
    if (items.isEmpty) return;
    showWhiteBirdOrdersModal(
      context: context,
      orders: items,
      onComplete: _completeOpenOrder,
      onDismiss: _dismissOpenOrder,
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
                    child: _buildHeader(theme, exchange),
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

    final canSwap = _canSwap(state);

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
                    const SizedBox(width: 40),
                    _buildDirectionIcon(theme, from, state),
                  ],
                ),
              ),
              if (to == null)
                _buildEmptyGetCard(theme, state)
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
                onPressed: canSwap ? () => _handleSwap(state) : null,
                color: canSwap
                    ? theme.primaryPurple
                    : theme.textSecondary.withValues(alpha: 0.18),
                valueColor: theme.buttonText,
                child: Text(
                  l10n.exchangePageConfirm,
                  style: theme.titleMedium.copyWith(
                    color: canSwap
                        ? theme.buttonText
                        : theme.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, ExchangeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_openOrders.isNotEmpty) _buildOrdersButton(theme),
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
              child: AppIconView(
                icon: AppIcon.settings,
                size: 22,
                color: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top-left open-orders icon with a badge counting PROCESSING WhiteBird orders.
  Widget _buildOrdersButton(AppTheme theme) {
    final count = _openOrders.length;
    return GestureDetector(
      onTap: _showOrdersModal,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppIconView(
              icon: AppIcon.history,
              size: 22,
              color: count > 0 ? theme.primaryPurple : theme.textSecondary,
            ),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: theme.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        assetSelector: (s) => s.payAssets,
        onSelected: _selectFrom,
      ),
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
          child: AppIconView(
            icon: AppIcon.swap,
            size: 20,
            color: canFlip
                ? theme.primaryPurple
                : theme.textSecondary.withValues(alpha: 0.4),
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

  Widget _buildEmptyGetCard(AppTheme theme, ExchangeState state) {
    final outs = state.outAssets;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
            color: theme.textSecondary.withValues(alpha: 0.15), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildEmptyTokenSelector(
            theme,
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
    final rateLabel =
        quote == null || from == null ? null : _rateLabel(from, to, quote);
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
            color: theme.textSecondary.withValues(alpha: 0.15), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
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
    bool enabled,
  ) {
    final text = Text(
      shortenAddress(address),
      style: theme.bodyText2.copyWith(
        color: enabled
            ? theme.primaryPurple
            : theme.textSecondary.withValues(alpha: 0.7),
        decoration:
            enabled ? TextDecoration.underline : TextDecoration.none,
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

  Widget _buildEmptyTokenSelector(AppTheme theme, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: enabled ? 0.2 : 0.08),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select',
              style: theme.bodyText1.copyWith(
                color: enabled
                    ? theme.textPrimary
                    : theme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 4),
            AppIconView(
              icon: AppIcon.arrowDown,
              size: 12,
              color: enabled
                  ? theme.textSecondary
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
