import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bearby/src/rust/api/exchange/bootstrap.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/exchange/pancakeswap.dart';
import 'package:bearby/src/rust/models/exchange/plunderswap.dart';
import 'package:bearby/src/rust/models/exchange/relay.dart';
import 'package:bearby/src/rust/models/exchange/uniswap.dart';

extension ExchangeProviderMeta on ExchangeProvider {
  ProviderCommon get common => map(
        relay: (v) => v.field0.common,
        uniswap: (v) => v.field0.common,
        pancakeSwap: (v) => v.field0.common,
        plunderSwap: (v) => v.field0.common,
        zilSwap: (v) => v.field0.common,
        sunSwap: (v) => v.field0.common,
      );

  ProviderQuote? get quote => map(
        relay: (v) => v.field0.quote,
        uniswap: (v) => v.field0.quote,
        pancakeSwap: (v) => v.field0.quote,
        plunderSwap: (v) => v.field0.quote,
        zilSwap: (v) => v.field0.quote,
        sunSwap: (v) => v.field0.quote,
      );

  int get defaultSlippageBps => map(
        relay: (v) => v.field0.cfg.defaultSlippageBps,
        uniswap: (v) => v.field0.cfg.defaultSlippageBps,
        pancakeSwap: (v) => v.field0.cfg.defaultSlippageBps,
        plunderSwap: (v) => v.field0.cfg.defaultSlippageBps,
        zilSwap: (_) => 50,
        sunSwap: (_) => 50,
      );

  bool get supportsPriceProtection => map(
        relay: (v) => v.field0.cfg.supportsPriceProtection,
        uniswap: (v) => v.field0.cfg.supportsPriceProtection,
        pancakeSwap: (v) => v.field0.cfg.supportsPriceProtection,
        plunderSwap: (v) => v.field0.cfg.supportsPriceProtection,
        zilSwap: (_) => false,
        sunSwap: (_) => false,
      );
}

/// Display lifecycle of the current quote, distinct from [loadingQuote] (which
/// only drives the countdown radial). The Get card renders off this so a
/// `quote == null` does not get mistaken for "still loading".
enum QuoteStatus { idle, loading, ready, noRoute }

class ExchangeState extends ChangeNotifier {
  static const Duration pollInterval = Duration(seconds: 10);

  List<ExchangeAsset> _payAssets = const [];
  List<ExchangeAsset> _getAssets = const [];
  ExchangeAsset? _fromAsset;
  ExchangeAsset? _toAsset;
  bool _loadingAssets = false;
  String? _assetsError;
  final Map<String, int> _slippageBps = <String, int>{};
  Timer? _pollTimer;
  bool _loadingQuote = false;
  String? _pendingAmountWei;
  QuoteStatus _quoteStatus = QuoteStatus.idle;

  List<ExchangeAsset> get payAssets => _payAssets;
  List<ExchangeAsset> get getAssets => _getAssets;
  ExchangeAsset? get fromAsset => _fromAsset;
  ExchangeAsset? get toAsset => _toAsset;
  bool get loadingAssets => _loadingAssets;
  String? get assetsError => _assetsError;
  bool get loadingQuote => _loadingQuote;
  QuoteStatus get quoteStatus => _quoteStatus;

  int slippageFor(ExchangeProvider provider) =>
      _slippageBps[provider.common.displayName] ?? provider.defaultSlippageBps;

  ExchangeProvider? get selectedProvider {
    final from = _fromAsset;
    if (from == null) return null;
    return from.providers.where((p) => p.quote != null).fold<ExchangeProvider?>(
      null,
      (best, provider) {
        if (best == null) return provider;
        final bestAmt =
            BigInt.tryParse(best.quote?.amountOut ?? '') ?? BigInt.zero;
        final amount =
            BigInt.tryParse(provider.quote?.amountOut ?? '') ?? BigInt.zero;
        return amount > bestAmt ? provider : best;
      },
    );
  }

  Future<void> bootstrap({
    required BigInt walletIndex,
    required BigInt accountIndex,
    required BigInt? activeChainHash,
    required ExchangeAsset? initialFrom,
  }) async {
    _fromAsset = initialFrom ?? _fromAsset;
    _assetsError = null;
    _loadingAssets = true;
    notifyListeners();

    try {
      final all = await bootstrapExchangeProviders(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );
      final pay =
          all.where((a) => a.token.chainHash == activeChainHash).toList();
      debugPrint(
        '[ExchangeState] bootstrap all=${all.length} pay=${pay.length} '
        'activeChainHash=$activeChainHash assets=${all.map(_assetDebug).join('; ')}',
      );
      final get = all;
      final from = pay.isNotEmpty
          ? pay.firstWhere((a) => a.token.native, orElse: () => pay.first)
          : _fromAsset;

      _payAssets = pay;
      _getAssets = get;
      _fromAsset = from;
      _toAsset = _toAsset == from ? null : _toAsset;
      _loadingAssets = false;
      notifyListeners();
      _restartPollingIfReady();
    } catch (e, st) {
      debugPrint('[ExchangeState] bootstrap failed: $e\n$st');
      _loadingAssets = false;
      _assetsError = e.toString();
      notifyListeners();
    }
  }

  void selectFrom(ExchangeAsset asset) {
    _fromAsset = asset;
    _quoteStatus = QuoteStatus.idle;
    _stopPolling();
    notifyListeners();
  }

  void selectTo(ExchangeAsset asset) {
    _toAsset = asset;
    _quoteStatus = QuoteStatus.idle;
    _restartPollingIfReady();
    notifyListeners();
  }

  void clearTo() {
    _toAsset = null;
    _stopPolling();
    _clearQuotes();
    _setQuoteStatus(QuoteStatus.idle);
    notifyListeners();
  }

  void setSlippage(String providerDisplayName, int bps) {
    _slippageBps[providerDisplayName] = bps;
    notifyListeners();
    unawaited(refreshOnce());
  }

  void setAmount(String wei) {
    debugPrint('[ExchangeState] setAmount wei=$wei');
    _pendingAmountWei = wei;
    _restartPollingIfReady();
  }

  void clearQuotes() {
    _stopPolling();
    _setQuoteStatus(QuoteStatus.idle);
  }

  void _restartPollingIfReady() {
    _stopPolling();
    if (_fromAsset == null || _toAsset == null) {
      _setQuoteStatus(QuoteStatus.idle);
      return;
    }
    unawaited(refreshOnce());
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(refreshOnce()));
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refreshOnce() async {
    final from = _fromAsset;
    final to = _toAsset;
    final amount = _pendingAmountWei;
    if (from == null ||
        to == null ||
        amount == null ||
        (BigInt.tryParse(amount) ?? BigInt.zero) <= BigInt.zero) {
      _stopPolling();
      _clearQuotes();
      _setQuoteStatus(QuoteStatus.idle);
      return;
    }

    debugPrint(
      '[ExchangeState] refreshOnce from=${from.token.symbol} '
      'to=${to.token.symbol} amount=$amount providers=${from.providers.length}',
    );
    _loadingQuote = true;
    _quoteStatus = QuoteStatus.loading;
    notifyListeners();
    try {
      final next =
          await refreshExchangeQuotes(from: from, to: to, amount: amount);
      _fromAsset = next;
      final quoted = next.providers.where((p) => p.quote != null).length;
      _quoteStatus = quoted > 0 ? QuoteStatus.ready : QuoteStatus.noRoute;
      debugPrint('[ExchangeState] refreshOnce done quotedProviders=$quoted');
    } catch (e) {
      debugPrint('[ExchangeState] quote refresh failed: $e');
      _quoteStatus = QuoteStatus.noRoute;
    } finally {
      _loadingQuote = false;
      notifyListeners();
    }
  }

  void _setQuoteStatus(QuoteStatus status) {
    if (_quoteStatus == status) return;
    _quoteStatus = status;
    notifyListeners();
  }

  /// Remove quotes from all providers on [_fromAsset] so the UI reflects a
  /// zero-amount state instead of showing stale data from a previous fetch.
  void _clearQuotes() {
    final from = _fromAsset;
    if (from == null) return;

    final cleared = ExchangeAsset(
      token: from.token,
      providers: from.providers.map(_stripQuote).toSet(),
      halted: from.halted,
    );

    if (_fromAsset != cleared) {
      _fromAsset = cleared;
      notifyListeners();
    }
  }

  static String _assetDebug(ExchangeAsset asset) {
    final providers =
        asset.providers.map((p) => p.common.displayName).join(',');
    return '${asset.token.symbol}:addrType=${asset.token.addrType}:native=${asset.token.native}:providers=[$providers]';
  }

  static ExchangeProvider _stripQuote(ExchangeProvider p) {
    return p.map(
      relay: (v) => ExchangeProvider.relay(RelayMeta(
        common: v.field0.common,
        cfg: v.field0.cfg,
        quote: null,
      )),
      uniswap: (v) => ExchangeProvider.uniswap(UniswapMeta(
        common: v.field0.common,
        cfg: v.field0.cfg,
        quote: null,
      )),
      pancakeSwap: (v) => ExchangeProvider.pancakeSwap(PancakeMeta(
        common: v.field0.common,
        cfg: v.field0.cfg,
        quote: null,
      )),
      plunderSwap: (v) => ExchangeProvider.plunderSwap(PlunderMeta(
        common: v.field0.common,
        cfg: v.field0.cfg,
        quote: null,
      )),
      zilSwap: (v) => ExchangeProvider.zilSwap(ZilSwapMeta(
        common: v.field0.common,
        quote: null,
      )),
      sunSwap: (v) => ExchangeProvider.sunSwap(SunSwapMeta(
        common: v.field0.common,
        quote: null,
      )),
    );
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
