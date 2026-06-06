import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bearby/src/rust/api/exchange.dart';
import 'package:bearby/src/rust/models/exchange.dart';

extension ExchangeProviderMeta on ExchangeProvider {
  ProviderCommon get common => map(
        relay: (v) => v.field0.common,
        uniswap: (v) => v.field0.common,
        pancakeSwap: (v) => v.field0.common,
        zilSwap: (v) => v.field0.common,
        sunSwap: (v) => v.field0.common,
      );

  ProviderQuote? get quote => map(
        relay: (v) => v.field0.quote,
        uniswap: (v) => v.field0.quote,
        pancakeSwap: (v) => v.field0.quote,
        zilSwap: (v) => v.field0.quote,
        sunSwap: (v) => v.field0.quote,
      );

  int get defaultSlippageBps => map(
        relay: (v) => v.field0.cfg.defaultSlippageBps,
        uniswap: (v) => v.field0.cfg.defaultSlippageBps,
        pancakeSwap: (v) => v.field0.cfg.defaultSlippageBps,
        zilSwap: (_) => 50,
        sunSwap: (_) => 50,
      );

  bool get supportsPriceProtection => map(
        relay: (v) => v.field0.cfg.supportsPriceProtection,
        uniswap: (v) => v.field0.cfg.supportsPriceProtection,
        pancakeSwap: (v) => v.field0.cfg.supportsPriceProtection,
        zilSwap: (_) => false,
        sunSwap: (_) => false,
      );
}

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

  List<ExchangeAsset> get payAssets => _payAssets;
  List<ExchangeAsset> get getAssets => _getAssets;
  ExchangeAsset? get fromAsset => _fromAsset;
  ExchangeAsset? get toAsset => _toAsset;
  bool get loadingAssets => _loadingAssets;
  String? get assetsError => _assetsError;
  bool get loadingQuote => _loadingQuote;

  int slippageFor(ExchangeProvider provider) =>
      _slippageBps[provider.common.displayName] ?? provider.defaultSlippageBps;

  ExchangeProvider? get selectedProvider {
    final from = _fromAsset;
    if (from == null) return null;
    return from.providers.where((p) => p.quote != null).fold<ExchangeProvider?>(
      null,
      (best, provider) {
        if (best == null) return provider;
        final bestAmt = BigInt.tryParse(best.quote?.amountOut ?? '') ?? BigInt.zero;
        final amount = BigInt.tryParse(provider.quote?.amountOut ?? '') ?? BigInt.zero;
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
      final pay = all.where((a) => a.token.chainHash == activeChainHash).toList();
      final get = all;
      final from = pay.isNotEmpty
          ? pay.firstWhere((a) => a.token.native, orElse: () => pay.first)
          : _fromAsset;
      final to = _toAsset ?? get.where((a) => a != from).firstOrNull;

      _payAssets = pay;
      _getAssets = get;
      _fromAsset = from;
      _toAsset = to;
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
    _stopPolling();
    notifyListeners();
  }

  void selectTo(ExchangeAsset asset) {
    _toAsset = asset;
    _restartPollingIfReady();
    notifyListeners();
  }

  void setSlippage(String providerDisplayName, int bps) {
    _slippageBps[providerDisplayName] = bps;
    notifyListeners();
    unawaited(refreshOnce());
  }

  void setAmount(String wei) {
    _pendingAmountWei = wei;
    _restartPollingIfReady();
  }

  void clearQuotes() {
    _stopPolling();
  }

  void _restartPollingIfReady() {
    _stopPolling();
    if (_fromAsset == null || _toAsset == null) return;
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
    if (from == null || to == null || amount == null) return;
    if ((BigInt.tryParse(amount) ?? BigInt.zero) <= BigInt.zero) return;

    _loadingQuote = true;
    notifyListeners();
    try {
      _fromAsset = await refreshExchangeQuotes(from: from, to: to, amount: amount);
    } catch (e) {
      debugPrint('[ExchangeState] quote refresh failed: $e');
    } finally {
      _loadingQuote = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
