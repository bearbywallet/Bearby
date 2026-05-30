import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/jazzicon.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/number_keyboard.dart';
import 'package:bearby/components/skeleton_box.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/modals/select_exchange_token.dart';
import 'package:bearby/modals/transfer.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/api/exchange.dart';
import 'package:bearby/src/rust/api/utils.dart';
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
  static const int _deadlineSeconds = 1200; // 20 minutes
  static const Duration _quoteDebounce = Duration(milliseconds: 400);

  late final AppState _appState;
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  Timer? _quoteTimer;

  _OrderType _orderType = _OrderType.swap;

  bool _loadingAssets = true;
  String? _assetsError;
  List<ExchangeAsset> _assets = const [];
  ExchangeAsset? _fromAsset;
  ExchangeAsset? _toAsset;

  String _amount = "0";
  bool _hasDecimalPoint = false;

  bool _loadingQuote = false;
  ExchangeQuoteInfo? _selectedQuote;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _btnController.dispose();
    super.dispose();
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
      final assets = all
          .where((a) =>
              a.token.chainHash == chainHash &&
              a.token.addrType == 1 &&
              a.providers
                  .any((p) => p.whenOrNull(uniswap: (_) => true) ?? false))
          .toList();

      ExchangeAsset? from;
      ExchangeAsset? to;
      if (assets.isNotEmpty) {
        from = assets.firstWhere((a) => a.token.native, orElse: () => assets.first);
        final outs = assets.where((a) => !a.token.native && a != from).toList();
        to = outs.isNotEmpty ? outs.first : null;
      }

      if (!mounted) return;
      setState(() {
        _assets = assets;
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

  /// Output assets: ERC20s on the active chain (native-out unwrap is unsupported),
  /// excluding whatever is selected on the "pay" side.
  List<ExchangeAsset> get _outAssets =>
      _assets.where((a) => !a.token.native && a != _fromAsset).toList();

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
      setState(() => _selectedQuote = null);
      return;
    }

    setState(() => _loadingQuote = true);

    try {
      final quotes = await fetchExchangeQuote(
        asset: from,
        fromAsset: from.token.addr,
        toAsset: to.token.addr,
        amount: amountWei.toString(),
        destination: account.addr,
      );
      // Keep the best (highest output) quote — it drives "You get" and the swap tx.
      quotes.sort((a, b) => (BigInt.tryParse(b.amountOut) ?? BigInt.zero)
          .compareTo(BigInt.tryParse(a.amountOut) ?? BigInt.zero));

      if (!mounted) return;
      setState(() {
        _selectedQuote = quotes.isNotEmpty ? quotes.first : null;
        _loadingQuote = false;
      });
    } catch (e) {
      debugPrint("exchange quote failed: $e");
      if (!mounted) return;
      setState(() {
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

  void _setMax(ExchangeAsset from) {
    final balance =
        BigInt.tryParse(from.token.balances[_appState.accountBalanceKey] ?? '') ??
            BigInt.zero;
    setState(() {
      _amount = fromWei(value: balance.toString(), decimals: from.token.decimals);
      _hasDecimalPoint = _amount.contains('.');
    });
    _scheduleQuote();
  }

  void _selectFrom(ExchangeAsset asset) {
    setState(() {
      _fromAsset = asset;
      _amount = "0";
      _hasDecimalPoint = false;
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
      _selectedQuote = null;
    });
    _scheduleQuote();
  }

  bool get _canSwap {
    final from = _fromAsset;
    if (from == null || _toAsset == null || _selectedQuote == null) return false;
    if (_amount.endsWith('.')) return false;
    final amountWei = toDecimalsWei(_amount, from.token.decimals);
    if (amountWei <= BigInt.zero) return false;
    final balance =
        BigInt.tryParse(from.token.balances[_appState.accountBalanceKey] ?? '') ??
            BigInt.zero;
    return amountWei <= balance;
  }

  // --- confirm ------------------------------------------------------------

  Future<void> _handleSwap() async {
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

    final fromToken = from.token;
    final isNativeIn = fromToken.native;
    final weth = quote.provider.whenOrNull(uniswap: (meta) => meta.weth);
    if (weth == null) {
      _showError('Unsupported provider');
      return;
    }
    final tokenIn = isNativeIn ? weth : fromToken.addr;
    final isLedger = wallet.walletType.contains(WalletType.ledger.name);

    _btnController.start();

    String? permitPassword;
    if (!isNativeIn) {
      if (isLedger) {
        _btnController.reset();
        _showError('ERC20 swaps are not supported on Ledger yet');
        return;
      }
      if (wallet.authType == 'none') {
        permitPassword = await _promptPassword();
        if (permitPassword == null) {
          _btnController.reset();
          return;
        }
      }
    }

    try {
      final amountInWei = toDecimalsWei(_amount, fromToken.decimals);
      final deadline = BigInt.from(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + _deadlineSeconds);

      final tx = await buildExchangeTx(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: wallet.selectedAccount,
        provider: quote.provider,
        tokenIn: tokenIn,
        tokenOut: to.token.addr,
        amountIn: amountInWei.toString(),
        amountOut: quote.amountOut,
        feeTier: quote.feeTier ?? 3000,
        slippageBps: _slippageBps,
        deadline: deadline,
        isNativeIn: isNativeIn,
        permitNonce: quote.permitNonce,
        password: permitPassword,
      );

      if (!mounted) {
        _btnController.stop();
        return;
      }
      _btnController.stop();
      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: account.addr,
        amount: _amount,
        token: fromToken,
        onConfirm: (_) => context.go(AppRoutes.history),
        onDismiss: () => _btnController.reset(),
      );
    } catch (e) {
      if (!mounted) return;
      _btnController.error();
      _showError(e.toString());
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _btnController.reset();
      });
    }
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    final theme = _appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text(
          l10n.exchangePageConfirm,
          style: theme.titleMedium.copyWith(color: theme.textPrimary),
        ),
        content: SmartInput(
          controller: controller,
          hint: 'Password',
          obscureText: true,
          autofocus: true,
          borderColor: theme.textPrimary,
          focusedBorderColor: theme.primaryPurple,
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              l10n.exchangePageConfirm,
              style: theme.button.copyWith(color: theme.primaryPurple),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return (result != null && result.isNotEmpty) ? result : null;
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
    if (!_loadingAssets && (_assetsError != null || from == null || to == null)) {
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

    // Render the structure instantly; swap in skeletons until the assets land.
    final Widget cards;
    if (from != null && to != null) {
      cards = Column(
        children: [
          _buildPayCard(theme, l10n, from),
          _buildDirectionButton(theme, from),
          _buildGetCard(theme, l10n, to),
        ],
      );
    } else {
      cards = Column(
        children: [
          _buildSkeletonCard(theme),
          _buildDirectionButton(theme, null),
          _buildSkeletonCard(theme),
        ],
      );
    }

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

  Widget _buildSkeletonCard(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 70, height: 12),
          SizedBox(height: 14),
          Row(
            children: [
              SkeletonBox(width: 130, height: 30),
              Spacer(),
              SkeletonBox(width: 100, height: 40, borderRadius: 20),
            ],
          ),
          SizedBox(height: 12),
        ],
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
            style: theme.titleLarge.copyWith(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tab(l10n.exchangePageTabSwap, _OrderType.swap, true),
          tab(l10n.exchangePageTabLimit, _OrderType.limit, false),
          tab(l10n.exchangePageTabBuySell, _OrderType.buySell, false),
        ],
      ),
    );
  }

  Widget _buildPayCard(AppTheme theme, AppLocalizations l10n, ExchangeAsset from) {
    final token = from.token;
    final balance =
        BigInt.tryParse(token.balances[_appState.accountBalanceKey] ?? '') ??
            BigInt.zero;
    final amountWei = toDecimalsWei(_amount, token.decimals);
    final exceeded = amountWei > balance;
    final (_, converted) = formatingAmount(
      amount: amountWei,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _amount,
                      style: theme.displayLarge.copyWith(
                        color: exceeded ? theme.danger : theme.textPrimary,
                        fontSize:
                            AdaptiveSize.getAdaptiveFontSize(context, 26),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (converted.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          converted,
                          style: theme.bodyText2
                              .copyWith(color: theme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              _buildTokenSelector(
                theme,
                token,
                () => showExchangeTokenSelectModal(
                  context: context,
                  assets: _assets,
                  onSelected: _selectFrom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                fromWei(value: balance.toString(), decimals: token.decimals),
                style: theme.bodyText2
                    .copyWith(color: theme.textPrimary.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _setMax(from),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.textPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Max',
                    style: theme.labelSmall.copyWith(
                      color: theme.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(AppTheme theme, ExchangeAsset? from) {
    // Flip is only valid when the current "pay" token can legally become an output
    // (ERC20-out only — native-out unwrap is unsupported by the backend).
    final canFlip = from != null && !from.token.native && _toAsset != null;

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

  Widget _buildGetCard(AppTheme theme, AppLocalizations l10n, ExchangeAsset to) {
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
                          height:
                              AdaptiveSize.getAdaptiveFontSize(context, 28),
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
