import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/ledger_device_card.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/ledger/ethereum/ethereum_ledger_application.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_ledger_application.dart';
import 'package:zilpay/mixins/eip712.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
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
  bool _isLoading = false;
  bool _isScanning = false;
  bool _obscurePassword = true;
  String? _error;
  List<LedgerDevice> _ledgerDevices = [];
  LedgerDevice? _selectedDevice;
  StreamSubscription<LedgerDevice>? _scanSubscription;
  Timer? _scanTimeout;
  int _scanRetries = 0;
  static const _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _authGuard = context.read<AuthGuard>();
    _checkLedgerDevices();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    super.dispose();
  }

  Future<void> _checkLedgerDevices() async {
    final appState = context.read<AppState>();
    final isLedgerWallet = appState.selectedWallet != -1 &&
        appState.wallets[appState.selectedWallet].walletType
            .contains(WalletType.ledger.name);

    if (!isLedgerWallet) return;

    final deviceId =
        appState.wallet?.walletType.split('.').last.replaceAll('"', '');
    final ledgerBle = LedgerInterface.ble(
      onPermissionRequest: (status) async =>
          status == AvailabilityState.poweredOn,
    );
    final ledgerUsb = LedgerInterface.usb();

    try {
      final bleDevices = await ledgerBle.devices;
      final usbDevices =
          Platform.isAndroid ? await ledgerUsb.devices : <LedgerDevice>[];
      final allDevices = [...bleDevices, ...usbDevices];

      setState(() {
        _ledgerDevices = allDevices;
        if (deviceId != null && allDevices.isNotEmpty) {
          _selectedDevice = allDevices.firstWhere(
            (device) => device.id.contains(deviceId),
          );
        } else {
          _selectedDevice = null;
        }
      });

      if (_ledgerDevices.isEmpty) {
        _startLedgerScan();
      } else if (_selectedDevice != null) {
        _verifyDeviceConnection();
      }
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!
            .signMessageModalContentFailedToScanLedger(e.toString());
      });
      _startLedgerScan();
    }
  }

  Future<void> _verifyDeviceConnection() async {
    if (_selectedDevice == null) return;
    try {
      final ledgerInterface = LedgerInterface.ble(
        onPermissionRequest: (status) async =>
            status == AvailabilityState.poweredOn,
      );
      await ledgerInterface.connect(_selectedDevice!);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _startLedgerScan();
    }
  }

  void _startLedgerScan() {
    if (_scanRetries >= _maxRetries) {
      setState(() {
        _isScanning = false;
        _error = AppLocalizations.of(context)!
            .signMessageModalContentFailedToScanLedger('Max retries reached');
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _scanRetries++;
    });

    final ledgerBle = LedgerInterface.ble(
      onPermissionRequest: (status) async {
        if (status != AvailabilityState.poweredOn) {
          setState(() => _error = AppLocalizations.of(context)!
              .signMessageModalContentBluetoothOff);
          return false;
        }
        return true;
      },
    );

    _scanSubscription = ledgerBle.scan().listen(
      (device) {
        if (mounted) {
          setState(() {
            if (!_ledgerDevices.any((d) => d.id == device.id)) {
              _ledgerDevices.add(device);
            }
            final appState = context.read<AppState>();
            final deviceId =
                appState.wallet?.walletType.split('.').last.replaceAll('"', '');
            if (deviceId != null &&
                device.id.contains(deviceId) &&
                _selectedDevice == null) {
              _selectedDevice = device;
              _stopLedgerScan();
              _verifyDeviceConnection();
            }
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _error = AppLocalizations.of(context)!
                .signMessageModalContentFailedToScanLedger(e.toString());
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _ledgerDevices.isEmpty) {
              _startLedgerScan();
            }
          });
        }
      },
    );

    _scanTimeout = Timer(const Duration(seconds: 15), () {
      _stopLedgerScan();
      if (mounted && _ledgerDevices.isEmpty) {
        setState(() => _error = AppLocalizations.of(context)!
            .signMessageModalContentNoLedgerDevices);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _startLedgerScan();
          }
        });
      }
    });
  }

  void _stopLedgerScan() {
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    setState(() => _isScanning = false);
  }

  Future<bool> _authenticate() async => _authService.authenticate(
        allowPinCode: true,
        reason: AppLocalizations.of(context)!.signMessageModalContentAuthReason,
      );

  Future<void> _signMessageLedger(AppState appState) async {
    try {
      if (appState.wallet == null || appState.account == null) {
        setState(() => _error = AppLocalizations.of(context)!
            .signMessageModalContentWalletNotSelected);
        return;
      }
      if (_selectedDevice == null) {
        setState(() => _error = AppLocalizations.of(context)!
            .signMessageModalContentLedgerNotSelected);
        return;
      }

      final accountIndex = appState.wallet!.selectedAccount.toInt();
      final ledgerInterface = LedgerInterface.ble(
        onPermissionRequest: (status) async =>
            status == AvailabilityState.poweredOn,
      );
      final connection = await ledgerInterface.connect(_selectedDevice!);

      if (widget.typedData != null) {
        final ethLedgerApp = EthereumLedgerApp(connection);
        final typedDataJson = jsonEncode(widget.typedData!.toJson());
        final eip712Hashes =
            await prepareEip712Message(typedDataJson: typedDataJson);
        final signature = await ethLedgerApp.signEIP712HashedMessage(
          eip712Hashes,
          appState.account!.index.toInt(),
        );
        final pubkey = appState.wallet!.accounts[accountIndex].pubKey;

        widget.onMessageSigned(pubkey, signature.toHexString());
      } else if (widget.message != null) {
        final chain = appState.getChain(appState.wallet!.defaultChainHash);
        Uint8List bytes = utf8.encode(widget.message!);
        String? sig;

        if (chain?.slip44 == 60) {
          final ethLedgerApp = EthereumLedgerApp(connection);
          final signature = await ethLedgerApp.signPersonalMessage(
            bytes,
            appState.account!.index.toInt(),
          );
          sig = signature.toHexString();
        } else if (chain?.slip44 == 313) {
          final zilLedgerApp = ZilliqaLedgerApp(connection);
          final hashBytes = await prepareMessage(
            walletIndex: BigInt.from(appState.selectedWallet),
            accountIndex: BigInt.from(accountIndex),
            message: widget.message!,
          );
          sig = await zilLedgerApp.signHash(
            hashBytes,
            appState.account!.index.toInt(),
          );
        } else {
          throw "unsupported network";
        }

        final pubkey = appState.wallet!.accounts[accountIndex].pubKey;

        widget.onMessageSigned(pubkey, sig);
      }
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!
          .signMessageModalContentFailedToSignMessage(e.toString()));
    }
  }

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
    final isLedgerWallet = appState.selectedWallet != -1 &&
        appState.wallets[appState.selectedWallet].walletType
            .contains(WalletType.ledger.name);
    if (isLedgerWallet) {
      await _signMessageLedger(appState);
    } else {
      await _signMessageNative(appState);
    }
    if (mounted) setState(() => _isLoading = false);
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
    final isLedgerWallet = appState.selectedWallet != -1 &&
        appState.wallets[appState.selectedWallet].walletType
            .contains(WalletType.ledger.name);

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
                  if (isLedgerWallet)
                    Column(
                      children: [
                        if (_isScanning)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  backgroundColor:
                                      secondaryColor.withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryColor),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.signMessageModalContentScanning,
                                  style: TextStyle(color: secondaryColor),
                                ),
                              ],
                            ),
                          ),
                        if (_ledgerDevices.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: _ledgerDevices
                                  .map((device) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: LedgerCard(
                                          device: device,
                                          isConnected:
                                              device.id == _selectedDevice?.id,
                                          isConnecting: false,
                                          onTap: () {
                                            if (!_isLoading) {
                                              setState(() =>
                                                  _selectedDevice = device);
                                              _verifyDeviceConnection();
                                            }
                                          },
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.signMessageModalContentTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signMessageModalContentDescription,
                          style: TextStyle(color: secondaryColor, fontSize: 14),
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
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
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
                                      Text(
                                        '${l10n.signMessageModalContentDomain} ${widget.typedData!.domain.name}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${l10n.signMessageModalContentChainId} ${widget.typedData!.domain.chainId}',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${l10n.signMessageModalContentContract} ${widget.typedData!.domain.verifyingContract}',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 14,
                                        ),
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
                                        Text(
                                          '${l10n.signMessageModalContentType} ${widget.typedData!.primaryType}',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    e.value is Map
                                                        ? jsonEncode(e.value)
                                                        : e.value.toString(),
                                                    style: TextStyle(
                                                        color: textColor,
                                                        fontSize: 14),
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
                                      style: TextStyle(
                                          color: textColor, fontSize: 16),
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
                                      style: TextStyle(
                                          color: theme.danger, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (appState.wallet!.authType == AuthMethod.none.name &&
                            !isLedgerWallet)
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
                          (isLedgerWallet &&
                              (_isScanning || _selectedDevice == null)),
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
}
