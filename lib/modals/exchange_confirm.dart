import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/copy_content.dart';
import 'package:bearby/components/exchange_provider_icon.dart';
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
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/exchange.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
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

  /// Live status of each planned step; mutated only inside [setState].
  final Map<_Step, _StepState> _stepStates = <_Step, _StepState>{};

  /// Indented sub-line shown under the currently active step.
  String? _hint;

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

    _plan = widget.isNativeIn
        ? const <_Step>[_Step.swap]
        : const <_Step>[_Step.approve, _Step.permit, _Step.swap];

    for (final s in _plan) {
      _stepStates[s] = _StepState.pending;
    }

    _payText = _format(appState, widget.fromToken, widget.amountInWei);
    _getText = _format(appState, widget.toToken, widget.amountOut);

    if (_isLedger) {
      appState.ledgerViewController.scanAndAutoConnect().then((_) {
        if (mounted) setState(() {});
      });
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
  // Software wallet confirm
  // -------------------------------------------------------------------------

  void _confirmSoftware(AppState appState) {
    final wallet = appState.wallet;
    if (wallet == null) {
      setState(() => _error = 'No active account');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _resetSteps();
    });

    final stream = executeExchangeSwap(
      walletIndex: appState.selectedWalletIndex,
      accountIndex: wallet.selectedAccount,
      provider: widget.provider,
      tokenIn: widget.tokenIn,
      tokenOut: widget.tokenOut,
      amountIn: widget.amountInWei,
      slippageBps: widget.slippageBps,
      isNativeIn: widget.isNativeIn,
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
      },
      onDone: () => _completeAndExit(appState),
    );
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
        _Step.swap => 'Swap on ${exchangeProviderName(widget.provider)}',
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

  Widget _buildMeta(AppState appState, AppTheme theme) {
    final addr = appState.account?.addr;
    final slippageText =
        '${(widget.slippageBps / 100).toStringAsFixed(2)}%  ·  Aggressive';

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (addr != null && addr.isNotEmpty) ...[
          Text(
            'To',
            style: theme.caption.copyWith(color: theme.textSecondary),
          ),
          CopyContent(address: addr),
          Text(
            '·',
            style: theme.caption.copyWith(color: theme.textSecondary),
          ),
        ],
        Text(
          slippageText,
          style: theme.caption.copyWith(color: theme.textSecondary),
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
                            _confirmSoftware(appState);
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
