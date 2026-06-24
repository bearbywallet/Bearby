import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bearby/src/rust/api/exchange/bootstrap.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/exchange/pancakeswap.dart';
import 'package:bearby/src/rust/models/exchange/plunderswap.dart';
import 'package:bearby/src/rust/models/exchange/relay.dart';
import 'package:bearby/src/rust/models/exchange/sunswap.dart';
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

  /// Whether the user can route the swap to an arbitrary recipient address.
  /// PlunderSwap's router contract credits the output to `msg.sender` and
  /// the swap ABI does not accept a recipient, so the user has no way to
  /// override it from this UI. ZilSwap's ZRC-2 swap path likewise does not
  /// surface a recipient parameter for the same reason. SunSwap's
  /// SunFeeRouter wrapper on TRON owns the output leg for fee collection
  /// and WTRX unwrapping, and its `swapExactInputSingle` / `swapExactInput`
  /// signatures do not expose a recipient — the wrapper hardcodes
  /// `address(this)` for native-out and `msg.sender` for token-out.
  bool get supportsCustomRecipient => map(
        relay: (_) => true,
        uniswap: (_) => true,
        pancakeSwap: (_) => true,
        plunderSwap: (_) => false,
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
  int _bootstrapGen = 0;

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

  /// Assets eligible as the "You get" side: all assets except the currently
  /// selected [fromAsset], further filtered to same-chain tokens or tokens
  /// that share a relay provider with the current from side.
  List<ExchangeAsset> get outAssets {
    final from = _fromAsset;
    // Exclude the "pay" token by token identity, NOT object identity: refreshOnce replaces
    // _fromAsset with a freshly-quoted instance, so `asset == from` would no longer match the
    // same token still sitting in _getAssets and would let the user pick from == to (e.g. TRX→TRX).
    final fromKey = from == null ? null : _tokenKey(from.token);
    return _getAssets.where((asset) {
      if (fromKey != null && _tokenKey(asset.token) == fromKey) return false;
      if (from == null) return true;
      if (asset.token.chainHash == from.token.chainHash) return true;
      return _hasRelay(from) && _hasRelay(asset);
    }).toList();
  }

  static bool _hasRelay(ExchangeAsset asset) =>
      asset.providers.any((p) => p.whenOrNull(relay: (_) => true) ?? false);

  Future<void> bootstrap({
    required BigInt walletIndex,
    required BigInt accountIndex,
    required BigInt? activeChainHash,
    required ExchangeAsset? initialFrom,
  }) async {
    final gen = ++_bootstrapGen;
    _fromAsset = initialFrom ?? _fromAsset;
    _assetsError = null;
    _loadingAssets = true;
    notifyListeners();

    try {
      // Phase 1 — sync FFI, instant. In-memory provider assembly only.
      final candidates = bootstrapExchangeProviders(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );
      _publishAssets(candidates, activeChainHash);
      _loadingAssets = false;
      notifyListeners();
      // Start polling immediately on candidates so the user sees an early quote before
      // validation finishes. Phase 2 restarts below with the validated (possibly pruned) set.
      _restartPollingIfReady();

      // Phase 2 — async FFI, parallel eager gates.
      final (validated, changed) =
          await validateExchangeProviders(assets: candidates);
      if (gen != _bootstrapGen) {
        return; // a newer bootstrap won → drop this stale result
      }
      if (!changed) {
        return; // no eager gate pruned anything → skip redundant republish + quote fetch
      }
      _publishAssets(validated, activeChainHash);
      notifyListeners();
      // Restart with validated assets: a provider pruned in phase 2 may have been the
      // currently-polling from/to, so the poll must re-resolve the pair.
      _restartPollingIfReady();
    } catch (e, st) {
      if (gen != _bootstrapGen) {
        return;
      }
      debugPrint('[ExchangeState] bootstrap failed: $e\n$st');
      _loadingAssets = false;
      _assetsError = e.toString();
      notifyListeners();
    }
  }

  // Single source of truth for pay/get/from selection. Reused by both bootstrap phases so the
  // interactive candidate list and the validated list derive selection identically. Preserves
  // an existing user selection across the phase 1 → phase 2 window: if the user picked a token
  // between phases, that selection is kept as long as the token survived validation (matched by
  // chain_hash+addr+addr_type — token identity, not volatile rate/balance state).
  void _publishAssets(List<ExchangeAsset> all, BigInt? activeChainHash) {
    final pay =
        all.where((a) => a.token.chainHash == activeChainHash).toList();
    final prevFrom = _fromAsset;
    final prevTo = _toAsset;
    // Preserve the current selection if the token survived into the new set; otherwise fall back
    // to the native default (or null when the active chain has nothing to pay with).
    final from = _resolveSelection(prevFrom, pay) ??
        (pay.isNotEmpty
            ? pay.firstWhere((a) => a.token.native, orElse: () => pay.first)
            : prevFrom);
    assert(() {
      debugPrint(
        '[ExchangeState] bootstrap all=${all.length} pay=${pay.length} '
        'activeChainHash=$activeChainHash assets=${all.map(_assetDebug).join('; ')}',
      );
      return true;
    }());
    _payAssets = pay;
    _getAssets = all;
    _fromAsset = from;
    // Preserve the "to" selection the same way; clear it only if it now equals "from".
    final to = _resolveSelection(prevTo, all);
    _toAsset = to == from ? null : to;
  }

  /// Look up `selection` in `pool` by token identity (chain_hash+addr+addr_type). Returns the
  /// refreshed instance from `pool` (so quote/balance state is current) or `null` if the token
  /// was pruned / selection was never set.
  ExchangeAsset? _resolveSelection(
    ExchangeAsset? selection,
    List<ExchangeAsset> pool,
  ) {
    if (selection == null) {
      return null;
    }
    final key = _tokenKey(selection.token);
    for (final asset in pool) {
      if (_tokenKey(asset.token) == key) {
        return asset;
      }
    }
    return null;
  }

  static ({BigInt chainHash, String addr, int addrType}) _tokenKey(
    FTokenInfo token,
  ) =>
      (
        chainHash: token.chainHash,
        addr: token.addr,
        addrType: token.addrType,
      );

  void selectFrom(ExchangeAsset asset) {
    _fromAsset = asset;
    _quoteStatus = QuoteStatus.idle;
    _stopPolling();
    notifyListeners();
  }

  void selectTo(ExchangeAsset asset) {
    // Never allow the "get" token to equal the "pay" token (compared by token identity, since
    // _fromAsset may be a freshly-quoted instance). Defense-in-depth behind outAssets filtering.
    final from = _fromAsset;
    if (from != null && _tokenKey(asset.token) == _tokenKey(from.token)) {
      return;
    }
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

  /// Stop the 10s quote poll timer. Use when the exchange page leaves the
  /// viewport (tab switch, route push). The next time the page becomes
  /// visible, _bootstrap will restart polling via _restartPollingIfReady.
  void pause() {
    _stopPolling();
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
        cfg: v.field0.cfg,
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
