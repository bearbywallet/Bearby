import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/ledger/ledger_connector.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/eip712.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showSignMessageModal({
  required BuildContext context,
  String? message,
  TypedDataEip712? typedData,
  required String appTitle,
  required String appIcon,
  ColorsInfo? colors,
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
  final Function(String, String) onMessageSigned;
  final VoidCallback? onDismiss;

  const _SignMessageModalContent({
    required this.appTitle,
    required this.appIcon,
    this.message,
    this.typedData,
    this.colors,
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
  late final AuthService _authService = AuthService();
  late final AuthGuard _authGuard;
  late final bool _isLedgerWallet;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  Timer? _scanTimeout;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _authGuard = context.read<AuthGuard>();
    _isLedgerWallet = appState.selectedWallet != -1 &&
        appState.wallets[appState.selectedWallet].walletType
            .contains(WalletType.ledger.name);

    if (_isLedgerWallet) {
      appState.ledgerViewController.scan();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _scanTimeout?.cancel();

    if (_isLedgerWallet) {
      final appState = context.read<AppState>();
      appState.ledgerViewController.stopScan();
    }

    super.dispose();
  }

  Future<void> _onDeviceLedgerOpen(DiscoveredDevice device) async {
    final appState = context.read<AppState>();
    await appState.ledgerViewController.open(device);
    setState(() {});
  }

  Future<bool> _authenticate() async => _authService.authenticate(
        allowPinCode: true,
        reason: AppLocalizations.of(context)!.signMessageModalContentAuthReason,
      );

  Future<void> _signMessageNative(AppState appState) async {
    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();
      final wallet = appState.wallet!;
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = wallet.selectedAccount;
      String? session;

      if (wallet.authType != AuthMethod.none.name) {
        if (!await _authenticate()) return;
        session = await _authGuard.getSession(sessionKey: wallet.walletAddress);
      }

      if (widget.typedData != null) {
        final typedDataJson = jsonEncode(widget.typedData!.toJson());
        final (pubkey, sig) = await signTypedDataEip712(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          identifiers: identifiers,
          typedDataJson: typedDataJson,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          sessionCipher: session,
          passphrase: "",
          title: widget.appTitle.isNotEmpty ? widget.appTitle : null,
          icon: widget.appIcon.isNotEmpty ? widget.appIcon : null,
        );
        widget.onMessageSigned(pubkey, sig);
      } else if (widget.message != null) {
        final (pubkey, sig) = await signMessage(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          identifiers: identifiers,
          message: widget.message!,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          sessionCipher: session,
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
        final account = wallet.accounts[wallet.selectedAccount.toInt()];

        if (widget.message != null) {
          final sig = await appState.ledgerViewController.signMesage(
            message: widget.message!,
            account: account,
            walletIndex: BigInt.from(appState.selectedWallet),
          );
          widget.onMessageSigned(account.pubKey, sig);
        } else if (widget.typedData != null) {
          final sig =
              await appState.ledgerViewController.signEIP712HashedMessage(
            account: account,
            walletIndex: BigInt.from(appState.selectedWallet),
            typedData: widget.typedData!,
          );
          widget.onMessageSigned(account.pubKey, sig);
        } else {
          throw "invalid message";
        }
      } else {
        await _signMessageNative(appState);
      }
    } catch (e) {
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
                          style: theme.bodyText2.copyWith(color: secondaryColor),
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
                                      _buildTypedDataRow(
                                        l10n.signMessageModalContentContract,
                                        widget.typedData!.domain
                                            .verifyingContract,
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
                                  SvgPicture.asset(
                                    'assets/icons/warning.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(
                                        theme.danger, BlendMode.srcIn),
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
                        if (appState.wallet!.authType == AuthMethod.none.name &&
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
                              rightIconPath: _obscurePassword
                                  ? 'assets/icons/close_eye.svg'
                                  : 'assets/icons/open_eye.svg',
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
                      backgroundColor: primaryColor,
                      textColor: theme.buttonText,
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
