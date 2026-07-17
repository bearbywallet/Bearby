import 'package:bearby/components/app_icon.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/ledger/ledger_connector.dart';
import 'package:bearby/ledger/models/discovered_device.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/api/btc.dart';
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
  /// Optional BTC sub-address to sign with (WalletConnect bip122 `address` param).
  String? btcSignAddress,
  required void Function(String, String) onMessageSigned,
  /// When set, BTC BIP-137 results include [BtcSignedMessageInfo.messageHashHex].
  void Function(BtcSignedMessageInfo)? onBtcMessageSigned,
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
      btcSignAddress: btcSignAddress,
      onMessageSigned: onMessageSigned,
      onBtcMessageSigned: onBtcMessageSigned,
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
  final String? btcSignAddress;
  final void Function(String, String) onMessageSigned;
  final void Function(BtcSignedMessageInfo)? onBtcMessageSigned;
  final VoidCallback? onDismiss;

  const _SignMessageModalContent({
    required this.appTitle,
    required this.appIcon,
    this.message,
    this.typedData,
    this.colors,
    this.btcSignAddress,
    required this.onMessageSigned,
    this.onBtcMessageSigned,
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
    setState(() {});
  }

  Future<void> _signMessageNative(AppState appState) async {
    try {
      final wallet = appState.wallet;
      if (wallet == null) {
        throw StateError('No wallet selected');
      }
      final walletIndex = appState.selectedWalletIndex;
      final accountIndex = wallet.selectedAccount;
      final password = _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null;
      final title = widget.appTitle.isNotEmpty ? widget.appTitle : null;
      final icon = widget.appIcon.isNotEmpty ? widget.appIcon : null;

      if (widget.typedData != null) {
        final typedData = widget.typedData;
        if (typedData == null) return;
        final typedDataJson = jsonEncode(typedData.toJson());
        final (pubkey, sig) = await signTypedDataEip712(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          typedDataJson: typedDataJson,
          password: password,
          passphrase: '',
          title: title,
          icon: icon,
        );
        widget.onMessageSigned(pubkey, sig);
      } else if (widget.message != null) {
        final message = widget.message;
        if (message == null) return;
        final account = appState.account;
        if (account != null && account.addrType == kBtcAddressType) {
          // Prefer the dApp-requested sub-address when provided (bip122).
          final signAddress = widget.btcSignAddress ?? account.addr;
          final signed = await btcSignMessageBip137(
            walletIndex: walletIndex,
            accountIndex: accountIndex,
            password: password,
            passphrase: '',
            address: signAddress,
            message: message,
          );
          final btcCb = widget.onBtcMessageSigned;
          if (btcCb != null) {
            btcCb(signed);
          } else {
            widget.onMessageSigned(signed.address, signed.signatureBase64);
          }
        } else {
          final (pubkey, sig) = await signMessage(
            walletIndex: walletIndex,
            accountIndex: accountIndex,
            message: message,
            password: password,
            passphrase: '',
            title: title,
            icon: icon,
          );
          widget.onMessageSigned(pubkey, sig);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = l10n == null
              ? e.toString()
              : l10n.signMessageModalContentFailedToSign(e.toString());
        });
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
          final sig = await appState.ledgerViewController.signMesage(
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
          throw "invalid message";
        }
      } else {
        await _signMessageNative(appState);
      }
    } catch (e) {
      debugPrint('_handleSignMessage error: $e');
      appState.ledgerViewController.stopScan();
      appState.ledgerViewController.disconnect();
      appState.ledgerViewController.scan();

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

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.modalBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_isLedgerWallet) ...[
                          LedgerConnector(
                            controller: appState.ledgerViewController,
                            onOpen: _onDeviceLedgerOpen,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          l10n.signMessageModalContentTitle,
                          style: theme.subtitle1.copyWith(color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signMessageModalContentDescription,
                          style:
                              theme.bodyText2.copyWith(color: secondaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                secondaryColor.withValues(alpha: 0.1),
                                primaryColor.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              if (widget.appIcon.isNotEmpty)
                                Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: primaryColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      widget.appIcon,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.message,
                                        color: secondaryColor,
                                        size: 24,
                                      ),
                                      loadingBuilder: (_, child, progress) =>
                                          progress == null
                                              ? child
                                              : CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: secondaryColor,
                                                ),
                                    ),
                                  ),
                                ),
                              Text(
                                widget.appTitle,
                                style: theme.bodyText1.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              if (widget.typedData != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildTypedDataRow(
                                        l10n.signMessageModalContentDomain,
                                        widget.typedData!.domain.name,
                                        theme,
                                        textColor,
                                        isTitle: true,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildTypedDataRow(
                                        l10n.signMessageModalContentChainId,
                                        widget.typedData!.domain.chainId
                                            .toString(),
                                        theme,
                                        secondaryColor,
                                      ),
                                      if (widget.typedData!.domain
                                              .verifyingContract !=
                                          null)
                                        _buildTypedDataRow(
                                          l10n.signMessageModalContentContract,
                                          widget.typedData!.domain
                                              .verifyingContract!,
                                          theme,
                                          secondaryColor,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTypedDataRow(
                                          l10n.signMessageModalContentType,
                                          widget.typedData!.primaryType,
                                          theme,
                                          textColor,
                                          isTitle: true,
                                        ),
                                        const SizedBox(height: 8),
                                        ...widget.typedData!.message.entries
                                            .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${e.key}: ',
                                                  style:
                                                      theme.bodyText2.copyWith(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    e.value is Map
                                                        ? jsonEncode(e.value)
                                                        : e.value.toString(),
                                                    style: theme.bodyText2
                                                        .copyWith(
                                                            color: textColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.message ??
                                          l10n.signMessageModalContentNoData,
                                      style: theme.bodyText1
                                          .copyWith(color: textColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppIconView(
                                    icon: AppIcon.warning,
                                    size: 24,
                                    color: theme.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: theme.bodyText2
                                          .copyWith(color: theme.danger),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (appState.wallet!.authType == "none" &&
                            !_isLedgerWallet)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SmartInput(
                              key: _passwordInputKey,
                              controller: _passwordController,
                              hint: l10n.signMessageModalContentPasswordHint,
                              fontSize: 18,
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              focusedBorderColor: primaryColor,
                              disabled: _isLoading,
                              obscureText: _obscurePassword,
                              rightIcon: AppIconState.passwordVisibility(obscured: _obscurePassword),
                              onRightIconTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              onChanged: (_) => setState(() => _error = null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SwipeButton(
                      text: _isLoading
                          ? l10n.signMessageModalContentProcessing
                          : l10n.signMessageModalContentSign,
                      disabled: _isLoading ||
                          (_isLedgerWallet &&
                              appState.ledgerViewController
                                      .connectedTransport ==
                                  null),
                      onSwipeComplete: () async => _handleSignMessage(appState),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypedDataRow(
    String label,
    String value,
    AppTheme theme,
    Color valueColor, {
    bool isTitle = false,
  }) {
    return Text(
      '$label $value',
      style: isTitle
          ? theme.bodyText1.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            )
          : theme.bodyText2.copyWith(color: valueColor),
    );
  }
}
