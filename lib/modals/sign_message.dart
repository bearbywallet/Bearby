import 'package:bearby/components/app_icon.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/sign_data_view.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/ledger/ledger_connector.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showSignMessageModal({
  required BuildContext context,
  String? message,
  TypedDataEip712? typedData,
  required String appTitle,
  required String appIcon,
  ColorsInfo? colors,
  BigInt? accountIndex,
  required Function(String, String) onMessageSigned,
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
    builder: (context) => _SignMessageModalContent(
      message: message,
      typedData: typedData,
      appTitle: appTitle,
      appIcon: appIcon,
      colors: colors,
      accountIndex: accountIndex,
      onMessageSigned: onMessageSigned,
      onDismiss: onDismiss,
    ),
  ).then((_) => onDismiss?.call());
}

class _SignMessageModalContent extends StatefulWidget {
  final String? message;
  final TypedDataEip712? typedData;
  final String appTitle;
  final String appIcon;
  final ColorsInfo? colors;
  final BigInt? accountIndex;
  final Function(String, String) onMessageSigned;
  final VoidCallback? onDismiss;

  const _SignMessageModalContent({
    required this.appTitle,
    required this.appIcon,
    this.message,
    this.typedData,
    this.colors,
    this.accountIndex,
    required this.onMessageSigned,
    this.onDismiss,
  });

  @override
  State<_SignMessageModalContent> createState() =>
      _SignMessageModalContentState();
}

class _SignMessageModalContentState extends State<_SignMessageModalContent> {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  late final AppState _appState;
  late final bool _isLedgerWallet;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  Timer? _scanTimeout;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    final wallet = _appState.selectedWallet >= 0
        ? _appState.wallets.elementAtOrNull(_appState.selectedWallet)
        : null;
    _isLedgerWallet =
        wallet?.walletType.contains(WalletType.ledger.name) ?? false;

    if (_isLedgerWallet) {
      _appState.ledgerViewController.scanAndAutoConnect().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _scanTimeout?.cancel();

    if (_isLedgerWallet) {
      _appState.ledgerViewController.stopScan();
    }

    super.dispose();
  }

  Future<void> _onDeviceLedgerOpen(DiscoveredDevice device) async {
    await _appState.ledgerViewController.open(device);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _signMessageNative(AppState appState) async {
    try {
      final wallet = appState.wallet!;
      final walletIndex = appState.selectedWalletIndex;
      final accountIndex = widget.accountIndex ?? wallet.selectedAccount;

      if (widget.typedData != null) {
        final typedDataJson = jsonEncode(widget.typedData!.toJson());
        final (pubkey, sig) = await signTypedDataEip712(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          typedDataJson: typedDataJson,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          passphrase: "",
          title: widget.appTitle.isNotEmpty ? widget.appTitle : null,
          icon: widget.appIcon.isNotEmpty ? widget.appIcon : null,
        );
        widget.onMessageSigned(pubkey, sig);
      } else if (widget.message != null) {
        final (pubkey, sig) = await signMessage(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          message: widget.message!,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          passphrase: "",
          title: widget.appTitle.isNotEmpty ? widget.appTitle : null,
          icon: widget.appIcon.isNotEmpty ? widget.appIcon : null,
        );
        widget.onMessageSigned(pubkey, sig);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!
            .signMessageModalContentFailedToSign(e.toString()));
      }
    }
  }

  void _handleSignMessage(AppState appState) async {
    setState(() => _isLoading = true);

    try {
      if (_isLedgerWallet) {
        final wallet = appState.wallet!;
        final account = appState.account;
        if (account == null) {
          throw Exception('Invalid account index');
        }

        if (widget.message != null) {
          final sig = await appState.ledgerViewController.signMessage(
            message: widget.message!,
            account: account,
            walletIndex: appState.selectedWalletIndex,
            slip44: wallet.slip44,
            bipPurpose: wallet.bip,
          );
          widget.onMessageSigned(account.pubKey ?? account.addr, sig);
        } else if (widget.typedData != null) {
          final sig =
              await appState.ledgerViewController.signEIP712HashedMessage(
            account: account,
            typedData: widget.typedData!,
            slip44: wallet.slip44,
          );
          widget.onMessageSigned(account.pubKey ?? account.addr, sig);
        } else {
          throw StateError('no message payload to sign');
        }
      } else {
        await _signMessageNative(appState);
      }
    } catch (e) {
      debugPrint('_handleSignMessage error: $e');
      appState.ledgerViewController.stopScan();
      appState.ledgerViewController.disconnect();
      appState.ledgerViewController.scan();

      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor =
        _parseColor(widget.colors?.background) ?? theme.cardBackground;
    final primaryColor =
        _parseColor(widget.colors?.primary) ?? theme.primaryPurple;
    final secondaryColor =
        _parseColor(widget.colors?.secondary) ?? theme.textSecondary;
    final textColor = _parseColor(widget.colors?.text) ?? theme.textPrimary;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final screenHeight = MediaQuery.sizeOf(context).height;

    final payload = SignPayload.from(
      message: widget.message,
      typedData: widget.typedData,
    );
    final typed = payload.typedData;
    final account = appState.account;

    final String kindLabel = switch (payload.kind) {
      SignPayloadKind.typedData => 'EIP-712',
      SignPayloadKind.siwe => 'Sign-In',
      SignPayloadKind.json => 'JSON',
      SignPayloadKind.hex => 'HEX',
      SignPayloadKind.text => l10n.signMessageModalContentTitle,
    };
    final String panelTitle = switch (payload.kind) {
      SignPayloadKind.typedData =>
        (typed!.primaryType.isNotEmpty ? typed.primaryType : 'EIP-712'),
      SignPayloadKind.siwe => payload.siwe!.domain,
      _ => kindLabel,
    };

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 1.5),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            adaptivePadding,
            0,
            adaptivePadding,
            MediaQuery.viewInsetsOf(context).bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.modalBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Who asks + what kind of signature + which account signs.
              Row(
                children: [
                  _buildAppIcon(theme, primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appTitle.isNotEmpty
                              ? widget.appTitle
                              : l10n.signMessageModalContentTitle,
                          style: theme.subtitle1.copyWith(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (account != null)
                          Text(
                            '${account.name} · ${shortenAddress(account.addr, leftSize: 6, rightSize: 4)}',
                            style:
                                theme.caption.copyWith(color: secondaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kindLabel,
                      style: theme.caption.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (typed != null) ...[
                const SizedBox(height: 10),
                SignDomainStrip(
                  domain: typed.domain.toJson(),
                  theme: theme,
                  accent: primaryColor,
                ),
              ],
              const SizedBox(height: 10),
              Flexible(
                child: SignDataPanel(
                  payload: payload,
                  title: panelTitle,
                  theme: theme,
                  accent: primaryColor,
                  textColor: textColor,
                  maxHeight: screenHeight * 0.42,
                ),
              ),
              if (_isLedgerWallet) ...[
                const SizedBox(height: 10),
                LedgerConnector(
                  controller: appState.ledgerViewController,
                  onOpen: _onDeviceLedgerOpen,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppIconView(
                        icon: AppIcon.warning, size: 14, color: theme.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.caption.copyWith(color: theme.danger),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (appState.wallet!.authType == "none" && !_isLedgerWallet) ...[
                const SizedBox(height: 10),
                SmartInput(
                  key: _passwordInputKey,
                  controller: _passwordController,
                  hint: l10n.signMessageModalContentPasswordHint,
                  fontSize: 16,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  focusedBorderColor: primaryColor,
                  disabled: _isLoading,
                  obscureText: _obscurePassword,
                  rightIcon: AppIconState.passwordVisibility(
                      obscured: _obscurePassword),
                  onRightIconTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: SwipeButton(
                  text: _isLoading
                      ? l10n.signMessageModalContentProcessing
                      : l10n.signMessageModalContentSign,
                  disabled: _isLoading ||
                      (_isLedgerWallet &&
                          appState.ledgerViewController.connectedTransport ==
                              null),
                  onSwipeComplete: () async => _handleSignMessage(appState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(AppTheme theme, Color primaryColor) {
    final fallback =
        AppIconView(icon: AppIcon.globe, size: 20, color: primaryColor);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.appIcon.isEmpty
          ? Center(child: fallback)
          : Image.network(
              widget.appIcon,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: fallback),
            ),
    );
  }
}
