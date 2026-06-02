import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/copy_content.dart';
import 'package:bearby/components/exchange_provider_icon.dart';
import 'package:bearby/components/gas_eip1559.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/jazzicon.dart';
import 'package:bearby/components/modal_drag_handle.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/ledger/ledger_connector.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/gas_eip1559.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/exchange.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/gas.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Step model
// ---------------------------------------------------------------------------

enum _Step { approve, permit, swap }

enum _StepState { pending, active, done, skipped }

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Confirm sheet for an exchange (swap or cross-chain bridge). Unlike the generic transfer modal,
/// this drives the whole approve → permit → swap sequence: software wallets run it as one batched
/// Rust call ([executeExchangeSwap]) under a single unlock; Ledger wallets sign each step on the
/// device (a device cannot sign a batch). Gas is always the Aggressive tier (applied in Rust).
void showExchangeConfirmModal({
  required BuildContext context,
  required ExchangeProvider provider,
  required FTokenInfo fromToken,
  required FTokenInfo toToken,
  required String amountInWei,
  required String tokenIn,
  required String tokenOut,
  required String amountOut,
  required bool isNativeIn,
  required bool isWrapUnwrap,
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
      provider: provider,
      fromToken: fromToken,
      toToken: toToken,
      amountInWei: amountInWei,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountOut: amountOut,
      isNativeIn: isNativeIn,
      isWrapUnwrap: isWrapUnwrap,
      slippageBps: slippageBps,
      onDone: onDone,
    ),
  ).then((_) => onDismiss?.call());
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _ExchangeConfirmContent extends StatefulWidget {
  final ExchangeProvider provider;
  final FTokenInfo fromToken;
  final FTokenInfo toToken;
  final String amountInWei;
  final String tokenIn;
  final String tokenOut;
  final String amountOut;
  final bool isNativeIn;
  final bool isWrapUnwrap;
  final int slippageBps;
  final VoidCallback onDone;

  const _ExchangeConfirmContent({
    required this.provider,
    required this.fromToken,
    required this.toToken,
    required this.amountInWei,
    required this.tokenIn,
    required this.tokenOut,
    required this.amountOut,
    required this.isNativeIn,
    required this.isWrapUnwrap,
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

  /// Ordered list of steps the user will walk through; built once in [initState].
  late final List<_Step> _plan;

  /// Pre-formatted "you pay" amount (symbol included from [formatingAmount]).
  late final String _payText;

  /// Pre-formatted "you get" amount (symbol included from [formatingAmount]).
  late final String _getText;

  /// Display metadata composed once; threaded into every tx Rust builds.
  late final ExchangeTxDisplay _display;

  /// Live status of each planned step; mutated only inside [setState].
  final Map<_Step, _StepState> _stepStates = <_Step, _StepState>{};

  /// Indented sub-line shown under the currently active step.
  String? _hint;

  /// Live gas params for the swap, fetched against a preview tx (native-in only).
  RequiredTxParamsInfo? _gasParams;
  TransactionRequestInfo? _gasPreviewTx;
  Timer? _gasTimer;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

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

    // Native input and pure wrap/unwrap are single-tx: no ERC-20 approve / Permit2 needed.
    _plan = (widget.isNativeIn || widget.isWrapUnwrap)
        ? const <_Step>[_Step.swap]
        : const <_Step>[_Step.approve, _Step.permit, _Step.swap];

    for (final s in _plan) {
      _stepStates[s] = _StepState.pending;
    }

    _payText = _format(appState, widget.fromToken, widget.amountInWei);
    _getText = _format(appState, widget.toToken, widget.amountOut);

    // Wrap/unwrap is provider-less (a direct WETH deposit/withdraw): a neutral icon and title,
    // no "\u00b7 Provider" suffix. A normal swap carries the chosen DEX's icon and name.
    final providerIcon = widget.isWrapUnwrap
        ? 'assets/icons/swap.svg'
        : exchangeProviderIconAsset(widget.provider);
    final providerName = exchangeProviderName(widget.provider);
    _display = ExchangeTxDisplay(
      providerIcon: providerIcon,
      swapTitle: widget.isWrapUnwrap
          ? wrapVerb(isNativeIn: widget.isNativeIn)
          : 'Swap',
      swapInfo: widget.isWrapUnwrap
          ? '$_payText \u2192 $_getText'
          : '$_payText \u2192 $_getText \u00b7 $providerName',
      approveTitle: 'Approve ${widget.fromToken.symbol}',
      permitTitle: 'Permit2 \u00b7 $providerName',
      outToken: BaseTokenInfo(
        value: widget.amountOut,
        symbol: widget.toToken.symbol,
        decimals: widget.toToken.decimals,
      ),
    );

    if (_isLedger) {
      appState.ledgerViewController.scanAndAutoConnect().then((_) {
        if (mounted) setState(() {});
      });
    }

    // Preview the swap's network fee up front. Only native-in swaps can be estimated without a
    // signed permit / on-chain allowance, so the rest fall back to the tier label.
    if (widget.isNativeIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initGasPreview());
    }
  }

  @override
  void dispose() {
    _gasTimer?.cancel();
    _swapSub?.cancel();
    _passwordController.dispose();
    if (_isLedger && context.mounted) {
      context.read<AppState>().ledgerViewController.stopScan();
    }
    super.dispose();
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
  // Gas preview (native-in only) — same pipeline as the transfer modal: build a
  // throwaway unsigned swap tx once, then poll [caclGasFee] on it. Never broadcasts.
  // -------------------------------------------------------------------------

  Future<void> _initGasPreview() async {
    final appState = context.read<AppState>();
    final wallet = appState.wallet;
    if (wallet == null) return;
    try {
      final nonce = await estimateSwapBaseNonce(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: wallet.selectedAccount,
      );
      final prep = await prepareExchangeSwap(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: wallet.selectedAccount,
        provider: widget.provider,
        tokenIn: widget.tokenIn,
        tokenOut: widget.tokenOut,
        amountIn: widget.amountInWei,
        slippageBps: widget.slippageBps,
        isNativeIn: true,
      );
      final tx = await finalizeExchangeSwap(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: wallet.selectedAccount,
        quoteBlob: prep.quoteBlob,
        permitSignature: null,
        nonce: nonce,
        swapTitle: _display.swapTitle,
        swapInfo: _display.swapInfo,
        providerIcon: _display.providerIcon,
        outToken: _display.outToken,
      );
      if (!mounted) return;
      _gasPreviewTx = tx;
      await _refreshGas();
      _gasTimer =
          Timer.periodic(const Duration(seconds: 12), (_) => _refreshGas());
    } catch (e) {
      // Non-blocking: the modal still shows the Aggressive tier label.
      debugPrint('swap gas preview failed: $e');
    }
  }

  Future<void> _refreshGas() async {
    final tx = _gasPreviewTx;
    if (tx == null || !mounted) return;
    final appState = context.read<AppState>();
    final wallet = appState.wallet;
    if (wallet == null) return;
    try {
      final gas = await caclGasFee(
        params: tx,
        walletIndex: appState.selectedWalletIndex,
        accountIndex: wallet.selectedAccount,
      );
      if (mounted) setState(() => _gasParams = gas);
    } catch (e) {
      debugPrint('swap gas refresh failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Software wallet confirm
  // -------------------------------------------------------------------------

  /// Returns a future that completes only when the swap stream is done or errors, so the awaiting
  /// [SwipeButton] keeps its loading state for the entire approve → permit → swap sequence.
  Future<void> _confirmSoftware(AppState appState) {
    final wallet = appState.wallet;
    if (wallet == null) {
      setState(() => _error = 'No active account');
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
      provider: widget.provider,
      tokenIn: widget.tokenIn,
      tokenOut: widget.tokenOut,
      amountIn: widget.amountInWei,
      slippageBps: widget.slippageBps,
      isNativeIn: widget.isNativeIn,
      display: _display,
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
    final wallet = appState.wallet;
    final account = appState.account;
    if (wallet == null || account == null) {
      setState(() => _error = 'No active account');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _resetSteps();
    });

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
        _onStage('approving', hint: 'Confirm approval on your Ledger…');
        final approval = await checkExchangeApproval(
          walletIndex: walletIndexBig,
          accountIndex: accountIndexBig,
          provider: widget.provider,
          tokenIn: widget.tokenIn,
          amountIn: widget.amountInWei,
          isNativeIn: widget.isNativeIn,
          nonce: baseNonce,
          approveTitle: _display.approveTitle,
          providerIcon: _display.providerIcon,
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
      if (mounted) setState(() => _hint = 'Preparing…');
      final prep = await prepareExchangeSwap(
        walletIndex: walletIndexBig,
        accountIndex: accountIndexBig,
        provider: widget.provider,
        tokenIn: widget.tokenIn,
        tokenOut: widget.tokenOut,
        amountIn: widget.amountInWei,
        slippageBps: widget.slippageBps,
        isNativeIn: widget.isNativeIn,
      );

      String? permitSignature;
      final permitJson = prep.permitTypedDataJson;
      if (permitJson != null) {
        _onStage('permit', hint: 'Confirm permit on your Ledger…');
        permitSignature = await ledger.signEIP712HashedMessage(
          typedData: TypedDataEip712.fromJsonString(permitJson),
          account: account,
          slip44: kEthereumSlip44,
        );
      }

      _onStage('swapping', hint: 'Confirm swap on your Ledger…');
      final swapTx = await finalizeExchangeSwap(
        walletIndex: walletIndexBig,
        accountIndex: accountIndexBig,
        quoteBlob: prep.quoteBlob,
        permitSignature: permitSignature,
        nonce: swapNonce,
        swapTitle: _display.swapTitle,
        swapInfo: _display.swapInfo,
        providerIcon: _display.providerIcon,
        outToken: _display.outToken,
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

  String _stepLabel(_Step step) => switch (step) {
        _Step.approve => 'Approve token',
        _Step.permit => 'Sign permit (EIP-712)',
        _Step.swap => widget.isWrapUnwrap
            ? wrapVerb(isNativeIn: widget.isNativeIn)
            : 'Swap on ${exchangeProviderName(widget.provider)}',
      };

  Widget _stepRow(AppTheme theme, _Step step) {
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
                _stepLabel(step),
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

  Widget _buildHero(AppState appState, AppTheme theme) {
    return Row(
      children: [
        _buildAvatar(appState, theme, widget.fromToken),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _payText,
            style: theme.bodyText1.copyWith(color: theme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SvgPicture.asset(
            'assets/icons/swap.svg',
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
          ),
        ),
        Expanded(
          child: Text(
            _getText,
            style: theme.bodyText1.copyWith(color: theme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        _buildAvatar(appState, theme, widget.toToken),
      ],
    );
  }

  Widget _buildAvatar(AppState appState, AppTheme theme, FTokenInfo token) {
    return SizedBox(
      width: 28,
      height: 28,
      child: ClipOval(
        child: AsyncImage(
          url: processTokenLogo(
            token: token,
            shortName: appState.chain?.shortName ?? '',
            theme: theme.value,
          ),
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorWidget: Jazzicon(seed: token.addr, diameter: 28),
          loadingWidget: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _plan.map((s) => _stepRow(theme, s)).toList(growable: false),
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

  Widget _buildMeta(AppState appState, AppTheme theme) {
    final addr = appState.account?.addr;
    final slippage = '${(widget.slippageBps / 100).toStringAsFixed(2)}%';
    const tier = GasFeeOption.aggressive;

    // Native-in: real Aggressive fee from the preview tx (`fast` is the total fee in wei).
    String? feeText;
    final gas = _gasParams;
    if (gas != null && widget.isNativeIn) {
      final (normalized, _) = formatingAmount(
        amount: BigInt.tryParse(gas.fast) ?? BigInt.zero,
        symbol: widget.fromToken.symbol,
        decimals: widget.fromToken.decimals,
        rate: widget.fromToken.rate,
        appState: appState,
      );
      feeText = '≈ $normalized';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _metaRow(theme, 'Provider', _routeValue(theme)),
        if (addr != null && addr.isNotEmpty)
          _metaRow(theme, 'Recipient', CopyContent(address: addr)),
        _metaRow(
          theme,
          'Slippage',
          Text(
            slippage,
            style: theme.bodyText1.copyWith(color: theme.textPrimary),
          ),
        ),
        if (feeText != null)
          _metaRow(
            theme,
            'Network fee',
            Text(
              feeText,
              style: theme.bodyText1.copyWith(color: theme.textPrimary),
            ),
          ),
        _metaRow(
          theme,
          'Gas tier',
          Text(
            '${tier.icon} ${tier.title(context)}',
            style: theme.bodyText1.copyWith(color: theme.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Route value for the meta panel: "Wrap"/"Unwrap" for a native↔wrapped op, else the chosen
  /// DEX's icon + name.
  Widget _routeValue(AppTheme theme) {
    if (widget.isWrapUnwrap) {
      return Text(
        wrapVerb(isNativeIn: widget.isNativeIn),
        style: theme.bodyText1.copyWith(color: theme.textPrimary),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          exchangeProviderIconAsset(widget.provider),
          width: 18,
          height: 18,
        ),
        const SizedBox(width: 6),
        Text(
          exchangeProviderName(widget.provider),
          style: theme.bodyText1.copyWith(color: theme.textPrimary),
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
                      _buildHero(appState, theme),
                      const SizedBox(height: 16),
                      // Force full-width so timeline stays left-aligned in the
                      // centred Column.
                      SizedBox(
                        width: double.infinity,
                        child: _buildTimeline(theme),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _buildMeta(appState, theme),
                      ),
                      if (needsPassword) ...[
                        const SizedBox(height: 12),
                        SmartInput(
                          controller: _passwordController,
                          hint: 'Password',
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
                            ? 'Unable to confirm'
                            : 'Swipe to swap',
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
