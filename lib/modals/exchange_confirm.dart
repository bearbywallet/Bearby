import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/copy_content.dart';
import 'package:bearby/components/exchange_provider_icon.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/modal_drag_handle.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/ledger/ledger_connector.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/exchange.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Step model
// ---------------------------------------------------------------------------

enum _Step { approve, permit, swap }

enum _StepState { pending, active, done, skipped }

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Confirm sheet for an exchange swap that doubles as a **route picker**: the caller passes every
/// provider quote (best-first) and the sheet lets the user pick one, showing each route's output and
/// (for native-in) a per-route gas estimate. It then drives the whole approve → permit → swap
/// sequence: software wallets run it as one batched Rust call ([executeExchangeSwap]) under a single
/// unlock; Ledger wallets sign each step on the device (a device cannot sign a batch). Gas is always
/// the Aggressive tier (applied in Rust).
void showExchangeConfirmModal({
  required BuildContext context,
  required List<ExchangeQuoteInfo> quotes,
  required FTokenInfo fromToken,
  required FTokenInfo toToken,
  required String amountInWei,
  required String tokenIn,
  required String tokenOut,
  required bool isNativeIn,
  required int slippageBps,
  required VoidCallback onDone,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => _ExchangeConfirmContent(
      quotes: quotes,
      fromToken: fromToken,
      toToken: toToken,
      amountInWei: amountInWei,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      isNativeIn: isNativeIn,
      slippageBps: slippageBps,
      onDone: onDone,
    ),
  ).then((_) => onDismiss?.call());
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _ExchangeConfirmContent extends StatefulWidget {
  final List<ExchangeQuoteInfo> quotes;
  final FTokenInfo fromToken;
  final FTokenInfo toToken;
  final String amountInWei;
  final String tokenIn;
  final String tokenOut;
  final bool isNativeIn;
  final int slippageBps;
  final VoidCallback onDone;

  const _ExchangeConfirmContent({
    required this.quotes,
    required this.fromToken,
    required this.toToken,
    required this.amountInWei,
    required this.tokenIn,
    required this.tokenOut,
    required this.isNativeIn,
    required this.slippageBps,
    required this.onDone,
  });

  @override
  State<_ExchangeConfirmContent> createState() =>
      _ExchangeConfirmContentState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ExchangeConfirmContentState extends State<_ExchangeConfirmContent> {
  final _passwordController = TextEditingController();
  StreamSubscription<String>? _swapSub;

  late final bool _isLedger;

  /// Ordered list of steps the user will walk through; built once in [didChangeDependencies].
  late final List<_Step> _plan;

  /// Pre-formatted "you pay" amount (symbol included from [formatingAmount]); constant across routes.
  late final String _payText;

  /// Index of the chosen route in [_ExchangeConfirmContent.quotes] (0 = best). Drives the display.
  int _selectedIndex = 0;

  /// Per-route total fee in wei (native-in only); keyed by quote index. Filled progressively.
  final Map<int, BigInt> _routeGasWei = <int, BigInt>{};

  /// Guards the one-time l10n-dependent init in [didChangeDependencies].
  bool _didInitDeps = false;

  /// Live status of each planned step; mutated only inside [setState].
  final Map<_Step, _StepState> _stepStates = <_Step, _StepState>{};

  /// Indented sub-line shown under the currently active step.
  String? _hint;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  ExchangeQuoteInfo get _selected => widget.quotes[_selectedIndex];
  bool get _isWrapUnwrap => _selected.isWrapUnwrap;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();
    final wallet = appState.selectedWallet >= 0
        ? appState.wallets.elementAtOrNull(appState.selectedWallet)
        : null;
    _isLedger = wallet?.walletType.contains(WalletType.ledger.name) ?? false;

    if (_isLedger) {
      appState.ledgerViewController.scanAndAutoConnect().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// One-time init that needs l10n (and a live context): the step plan, the constant "you pay"
  /// text, and the per-route gas preview. Runs here rather than [initState] because
  /// `AppLocalizations.of` is only valid once dependencies are available.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDeps) return;
    _didInitDeps = true;

    final appState = context.read<AppState>();

    // Native input and pure wrap/unwrap are single-tx: no ERC-20 approve / Permit2 needed.
    _plan = (widget.isNativeIn || _isWrapUnwrap)
        ? const <_Step>[_Step.swap]
        : const <_Step>[_Step.approve, _Step.permit, _Step.swap];
    for (final s in _plan) {
      _stepStates[s] = _StepState.pending;
    }

    _payText = _format(appState, widget.fromToken, widget.amountInWei);

    // Preview each route's network fee up front. Only native-in swaps can be estimated without a
    // signed permit / on-chain allowance, so ERC-20-input routes show no gas.
    if (widget.isNativeIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _estimateAllRouteGas());
    }
  }

  @override
  void dispose() {
    _swapSub?.cancel();
    _passwordController.dispose();
    if (_isLedger && context.mounted) {
      context.read<AppState>().ledgerViewController.stopScan();
    }
    super.dispose();
  }

  /// Localized "Wrap"/"Unwrap" verb for a native↔wrapped op (direction from [_ExchangeConfirmContent.isNativeIn]).
  String _wrapVerb(AppLocalizations l10n) =>
      widget.isNativeIn ? l10n.exchangeConfirmWrap : l10n.exchangeConfirmUnwrap;

  /// "You get" text for a given route (recomputed per selection).
  String _getTextFor(AppState appState, ExchangeQuoteInfo quote) =>
      _format(appState, widget.toToken, quote.amountOut);

  /// Build the tx display metadata for [quote]. Wrap/unwrap is provider-less (a direct WETH
  /// deposit/withdraw): a neutral icon/title and no "\u00b7 Provider" suffix; a normal swap carries the
  /// chosen DEX's icon and name. Single source of truth for both the confirm flow and gas preview.
  ExchangeTxDisplay _displayFor(
    AppState appState,
    AppLocalizations l10n,
    ExchangeQuoteInfo quote,
  ) {
    final providerName = exchangeProviderName(quote.provider);
    final getText = _getTextFor(appState, quote);
    final wrapTitle = _wrapVerb(l10n);
    return ExchangeTxDisplay(
      providerIcon: quote.isWrapUnwrap
          ? 'assets/icons/swap.svg'
          : exchangeProviderIconAsset(quote.provider),
      swapTitle: quote.isWrapUnwrap ? wrapTitle : l10n.exchangePageTabSwap,
      swapInfo: quote.isWrapUnwrap
          ? '$_payText \u2192 $getText'
          : '$_payText \u2192 $getText \u00b7 $providerName',
      approveTitle: l10n.exchangeHistoryApprove(widget.fromToken.symbol),
      permitTitle: l10n.exchangeHistoryPermit(providerName),
      outToken: BaseTokenInfo(
        value: quote.amountOut,
        symbol: widget.toToken.symbol,
        decimals: widget.toToken.decimals,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Wraps [formatingAmount] and returns only the formatted native-token string.
  String _format(AppState appState, FTokenInfo token, String amountWei) {
    final (text, _) = formatingAmount(
      amount: BigInt.tryParse(amountWei) ?? BigInt.zero,
      symbol: token.symbol,
      decimals: token.decimals,
      rate: token.rate,
      appState: appState,
    );
    return text;
  }

  /// Mark [step] as active; any earlier planned-but-still-pending step is skipped.
  void _activate(_Step step) {
    if (!_stepStates.containsKey(step)) return;
    for (final s in _plan) {
      if (s == step) break;
      if (_stepStates[s] == _StepState.pending) {
        _stepStates[s] = _StepState.skipped;
      }
    }
    _stepStates[step] = _StepState.active;
  }

  /// Unified stage handler fed by both the software stream and the Ledger flow.
  void _onStage(String event, {String? hint}) {
    if (!mounted) return;
    setState(() {
      _hint = hint;
      switch (event) {
        case 'approving':
          _activate(_Step.approve);
        case 'approved':
          _stepStates[_Step.approve] = _StepState.done;
        case 'permit':
          _activate(_Step.permit);
        case 'swapping':
          if (_stepStates[_Step.permit] == _StepState.active) {
            _stepStates[_Step.permit] = _StepState.done;
          }
          _activate(_Step.swap);
        case 'done':
          _stepStates[_Step.swap] = _StepState.done;
          _hint = null;
      }
    });
  }

  /// Refresh balances, close the sheet, then hand navigation back to the opener.
  /// Mirrors the completion pattern used in stake_modal.dart.
  Future<void> _completeAndExit(AppState appState) async {
    await appState.syncData();
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onDone();
  }

  /// Reset all steps to [_StepState.pending] before a fresh confirm attempt.
  /// Must be called from inside a [setState] callback.
  void _resetSteps() {
    for (final s in _plan) {
      _stepStates[s] = _StepState.pending;
    }
    _hint = null;
  }

  // -------------------------------------------------------------------------
  // Per-route gas preview (native-in only) — reuses the swap-build pipeline: build a throwaway
  // unsigned swap tx per route and run [caclGasFee] on it. Never broadcasts. ERC-20-input routes
  // can't be simulated before the on-chain approval, so they show no gas.
  // -------------------------------------------------------------------------

  void _estimateAllRouteGas() {
    final appState = context.read<AppState>();
    final wallet = appState.wallet;
    if (wallet == null || !widget.isNativeIn) return;
    // Independent futures so each row fills in as it resolves; failures are swallowed per-route.
    for (var i = 0; i < widget.quotes.length; i++) {
      unawaited(_estimateRouteGas(appState, wallet.selectedAccount, i));
    }
  }

  Future<void> _estimateRouteGas(
    AppState appState,
    BigInt accountIndex,
    int index,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final quote = widget.quotes[index];
    try {
      final nonce = await estimateSwapBaseNonce(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: accountIndex,
      );
      final prep = await prepareExchangeSwap(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: accountIndex,
        provider: quote.provider,
        tokenIn: widget.tokenIn,
        tokenOut: widget.tokenOut,
        amountIn: widget.amountInWei,
        slippageBps: widget.slippageBps,
        isNativeIn: true,
      );
      final disp = _displayFor(appState, l10n, quote);
      final tx = await finalizeExchangeSwap(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: accountIndex,
        quoteBlob: prep.quoteBlob,
        permitSignature: null,
        nonce: nonce,
        swapTitle: disp.swapTitle,
        swapInfo: disp.swapInfo,
        providerIcon: disp.providerIcon,
        outToken: disp.outToken,
      );
      final gas = await caclGasFee(
        params: tx,
        walletIndex: appState.selectedWalletIndex,
        accountIndex: accountIndex,
      );
      final wei = BigInt.tryParse(gas.fast);
      if (mounted && wei != null) {
        setState(() => _routeGasWei[index] = wei);
      }
    } catch (e) {
      // Non-blocking: the row simply shows no gas estimate.
      debugPrint('route gas estimate failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Software wallet confirm
  // -------------------------------------------------------------------------

  /// Returns a future that completes only when the swap stream is done or errors, so the awaiting
  /// [SwipeButton] keeps its loading state for the entire approve → permit → swap sequence.
  Future<void> _confirmSoftware(AppState appState) {
    final l10n = AppLocalizations.of(context);
    final wallet = appState.wallet;
    if (wallet == null || l10n == null) {
      setState(() => _error = l10n?.exchangeConfirmNoAccount ?? '');
      return Future.value();
    }

    setState(() {
      _loading = true;
      _error = null;
      _resetSteps();
    });

    final completer = Completer<void>();
    final stream = executeExchangeSwap(
      walletIndex: appState.selectedWalletIndex,
      accountIndex: wallet.selectedAccount,
      provider: _selected.provider,
      tokenIn: widget.tokenIn,
      tokenOut: widget.tokenOut,
      amountIn: widget.amountInWei,
      slippageBps: widget.slippageBps,
      isNativeIn: widget.isNativeIn,
      display: _displayFor(appState, l10n, _selected),
      password: wallet.authType == 'none' ? _passwordController.text : null,
    );

    _swapSub = stream.listen(
      (step) => _onStage(step),
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.toString();
          });
        }
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        // onError already set _error and _loading=false; onDone always fires
        // after onError on a closing stream — guard against accidental pop+nav.
        if (!completer.isCompleted) completer.complete();
        if (_error != null) return;
        _completeAndExit(appState);
      },
    );

    return completer.future;
  }

  // -------------------------------------------------------------------------
  // Ledger confirm (sign each step on the device — no batch)
  // -------------------------------------------------------------------------

  Future<void> _confirmLedger(AppState appState) async {
    final l10n = AppLocalizations.of(context);
    final wallet = appState.wallet;
    final account = appState.account;
    if (wallet == null || account == null || l10n == null) {
      setState(() => _error = l10n?.exchangeConfirmNoAccount ?? '');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _resetSteps();
    });

    final disp = _displayFor(appState, l10n, _selected);
    final ledger = appState.ledgerViewController;
    final walletIndexBig = appState.selectedWalletIndex;
    final accountIndexBig = wallet.selectedAccount;
    final walletIndexInt = appState.selectedWallet;
    final accountIndexInt = wallet.selectedAccount.toInt();

    try {
      final baseNonce = await estimateSwapBaseNonce(
        walletIndex: walletIndexBig,
        accountIndex: accountIndexBig,
      );
      var swapNonce = baseNonce;

      if (!widget.isNativeIn) {
        _onStage('approving', hint: l10n.exchangeConfirmHintApprove);
        final approval = await checkExchangeApproval(
          walletIndex: walletIndexBig,
          accountIndex: accountIndexBig,
          provider: _selected.provider,
          tokenIn: widget.tokenIn,
          amountIn: widget.amountInWei,
          isNativeIn: widget.isNativeIn,
          nonce: baseNonce,
          approveTitle: disp.approveTitle,
          providerIcon: disp.providerIcon,
        );
        if (approval != null) {
          final sig = await ledger.signTransaction(
            transaction: approval,
            walletIndex: walletIndexInt,
            accountIndex: accountIndexInt,
            account: account,
          );
          await sendSignedTransactions(
            tx: approval,
            sig: sig,
            walletIndex: walletIndexInt,
            accountIndex: accountIndexInt,
          );
          _onStage('approved');
          swapNonce = baseNonce + BigInt.one;
        }
      }

      // Gap between approve and swap prep: show a transient hint with no step change.
      if (mounted) setState(() => _hint = l10n.exchangeConfirmHintPreparing);
      final prep = await prepareExchangeSwap(
        walletIndex: walletIndexBig,
        accountIndex: accountIndexBig,
        provider: _selected.provider,
        tokenIn: widget.tokenIn,
        tokenOut: widget.tokenOut,
        amountIn: widget.amountInWei,
        slippageBps: widget.slippageBps,
        isNativeIn: widget.isNativeIn,
      );

      String? permitSignature;
      final permitJson = prep.permitTypedDataJson;
      if (permitJson != null) {
        _onStage('permit', hint: l10n.exchangeConfirmHintPermit);
        permitSignature = await ledger.signEIP712HashedMessage(
          typedData: TypedDataEip712.fromJsonString(permitJson),
          account: account,
          slip44: kEthereumSlip44,
        );
      }

      _onStage('swapping', hint: l10n.exchangeConfirmHintSwap);
      final swapTx = await finalizeExchangeSwap(
        walletIndex: walletIndexBig,
        accountIndex: accountIndexBig,
        quoteBlob: prep.quoteBlob,
        permitSignature: permitSignature,
        nonce: swapNonce,
        swapTitle: disp.swapTitle,
        swapInfo: disp.swapInfo,
        providerIcon: disp.providerIcon,
        outToken: disp.outToken,
      );
      final swapSig = await ledger.signTransaction(
        transaction: swapTx,
        walletIndex: walletIndexInt,
        accountIndex: accountIndexInt,
        account: account,
      );
      await sendSignedTransactions(
        tx: swapTx,
        sig: swapSig,
        walletIndex: walletIndexInt,
        accountIndex: accountIndexInt,
      );

      _onStage('done');
      await _completeAndExit(appState);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDeviceLedgerOpen(DiscoveredDevice device) async {
    final appState = context.read<AppState>();
    await appState.ledgerViewController.open(device);
    if (mounted) setState(() {});
  }

  // -------------------------------------------------------------------------
  // UI helpers — pure widget builders, no side-effects
  // -------------------------------------------------------------------------

  /// Glyph for a step row: ✓ done / ◐ spinner / ○ pending / — skipped.
  Widget _glyph(AppTheme theme, _StepState state) => switch (state) {
        _StepState.done => SvgPicture.asset(
            'assets/icons/check.svg',
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(theme.success, BlendMode.srcIn),
          ),
        _StepState.active => SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: theme.primaryPurple,
            ),
          ),
        _StepState.pending => Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.modalBorder, width: 1.5),
            ),
          ),
        _StepState.skipped => SizedBox(
            width: 14,
            height: 14,
            child: Center(
              child: Container(
                width: 10,
                height: 2,
                color: theme.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
      };

  Color _stepColor(AppTheme theme, _StepState state) => switch (state) {
        _StepState.done => theme.success,
        _StepState.active => theme.primaryPurple,
        _StepState.pending => theme.textSecondary,
        _StepState.skipped => theme.textSecondary.withValues(alpha: 0.4),
      };

  String _stepLabel(AppLocalizations l10n, _Step step) => switch (step) {
        _Step.approve => l10n.exchangeConfirmStepApprove,
        _Step.permit => l10n.exchangeConfirmStepPermit,
        _Step.swap => _isWrapUnwrap ? _wrapVerb(l10n) : l10n.exchangePageTabSwap,
      };

  Widget _stepRow(AppTheme theme, AppLocalizations l10n, _Step step) {
    final state = _stepStates[step] ?? _StepState.pending;
    final activeHint = _hint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _glyph(theme, state),
              const SizedBox(width: 10),
              Text(
                _stepLabel(l10n, step),
                style: theme.bodyText1.copyWith(
                  color: _stepColor(theme, state),
                  decoration: state == _StepState.skipped
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
          if (state == _StepState.active && activeHint != null)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                activeHint,
                style: theme.labelSmall.copyWith(color: theme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }



  /// Selected route's gas as a native-token amount string, or `null` when not yet estimated /
  /// not available (ERC-20 input). Pre-sized formatting via [formatingAmount].
  String? _routeGasText(AppState appState, int index) {
    final wei = _routeGasWei[index];
    if (wei == null) return null;
    final (text, _) = formatingAmount(
      amount: wei,
      symbol: widget.fromToken.symbol,
      decimals: widget.fromToken.decimals,
      rate: widget.fromToken.rate,
      appState: appState,
    );
    return text;
  }

  Widget _buildRouteList(AppState appState, AppTheme theme, AppLocalizations l10n) {
    return Column(
      children: List<Widget>.generate(
        widget.quotes.length,
        (i) => _buildRouteRow(appState, theme, l10n, i),
        growable: false,
      ),
    );
  }

  Widget _buildRouteRow(
    AppState appState,
    AppTheme theme,
    AppLocalizations l10n,
    int index,
  ) {
    final quote = widget.quotes[index];
    final selected = index == _selectedIndex;
    final isBest = index == 0 && widget.quotes.length > 1;
    final selectable = widget.quotes.length > 1;
    final out = _format(appState, widget.toToken, quote.amountOut);
    final gasText = _routeGasText(appState, index);
    final gasLabel = gasText != null
        ? l10n.exchangeConfirmAfterGas(gasText)
        : l10n.exchangeConfirmGasNone;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectable ? () => setState(() => _selectedIndex = index) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.primaryPurple : theme.modalBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Provider icon (or swap icon for wrap/unwrap).
            if (quote.isWrapUnwrap)
              SvgPicture.asset(
                'assets/icons/swap.svg',
                width: 28,
                height: 28,
                colorFilter:
                    ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
              )
            else
              SvgPicture.asset(
                exchangeProviderIconAsset(quote.provider),
                width: 28,
                height: 28,
              ),
            const SizedBox(width: 12),
            // Pay → Get amounts + gas.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_payText → $out',
                    style:
                        theme.bodyText1.copyWith(color: theme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gasLabel,
                    style: theme.bodyText2
                        .copyWith(color: theme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isBest)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.exchangeConfirmBest,
                  style: theme.labelSmall.copyWith(
                    color: theme.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _plan.map((s) => _stepRow(theme, l10n, s)).toList(growable: false),
    );
  }

  Widget _metaRow(AppTheme theme, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: theme.bodyText2.copyWith(color: theme.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(AppState appState, AppTheme theme, AppLocalizations l10n) {
    final addr = appState.account?.addr;
    final slippage = '${(widget.slippageBps / 100).toStringAsFixed(2)}%';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (addr != null && addr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  l10n.exchangeConfirmRecipient,
                  style:
                      theme.bodyText2.copyWith(color: theme.textSecondary),
                ),
                const Spacer(),
                CopyContent(address: addr),
              ],
            ),
          ),
        _metaRow(
          theme,
          l10n.exchangeConfirmSlippage,
          Text(
            slippage,
            style: theme.bodyText1.copyWith(color: theme.textPrimary),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final wallet = appState.wallet;
    final needsPassword =
        !_isLedger && wallet != null && wallet.authType == 'none';
    final ledgerNotReady =
        _isLedger && appState.ledgerViewController.connectedTransport == null;

    // Capture nullable fields to local finals so Dart can promote the type.
    final currentError = _error;

    return PopScope(
      canPop: !_loading,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.modalBorder, width: 2),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalDragHandle(theme: theme),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLedger)
                        LedgerConnector(
                          controller: appState.ledgerViewController,
                          onOpen: _onDeviceLedgerOpen,
                        ),
                      if (currentError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassMessage(
                            message: currentError,
                            type: GlassMessageType.error,
                            onDismiss: () => setState(() => _error = null),
                          ),
                        ),
                      _buildRouteList(appState, theme, l10n),
                      const SizedBox(height: 8),
                      // Force full-width so timeline stays left-aligned in the
                      // centred Column.
                      SizedBox(
                        width: double.infinity,
                        child: _buildTimeline(theme, l10n),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _buildMeta(appState, theme, l10n),
                      ),
                      if (needsPassword) ...[
                        const SizedBox(height: 12),
                        SmartInput(
                          controller: _passwordController,
                          hint: l10n.exchangeConfirmPassword,
                          fontSize: 18,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: theme.primaryPurple,
                          disabled: _loading,
                          obscureText: _obscurePassword,
                          rightIconPath: _obscurePassword
                              ? 'assets/icons/close_eye.svg'
                              : 'assets/icons/open_eye.svg',
                          onRightIconTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          textColor: theme.textSecondary,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwipeButton(
                        text: currentError != null
                            ? l10n.exchangeConfirmUnable
                            : l10n.exchangeConfirmSwipe,
                        disabled: _loading || ledgerNotReady,
                        onSwipeComplete: () async {
                          if (_isLedger) {
                            await _confirmLedger(appState);
                          } else {
                            await _confirmSoftware(appState);
                          }
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.viewInsetsOf(context).bottom > 0
                            ? 16
                            : 32,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
