import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zilliqa_ledger_flutter/zilliqa_ledger_flutter.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/ledger_item.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/ledger_connect_dialog.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/theme_provider.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  late Ledger _ledger;
  final AuthService _authService = AuthService();
  List<AuthMethod> _authMethods = [AuthMethod.none];

  final _btnController = RoundedLoadingButtonController();
  late AuthGuard _authGuard;
  late AppState _appState;

  List<LedgerDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  int _selected = -1;
  String? _error;

  @override
  void initState() {
    super.initState();

    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLedger();
      _checkAuthMethods();
      Future.delayed(const Duration(milliseconds: 1000), () {
        _startScanning();
      });
    });
  }

  @override
  void dispose() {
    _btnController.dispose();
    _ledger.close(ConnectionType.ble);

    if (Platform.isAndroid) {
      _ledger.close(ConnectionType.usb);
    }

    super.dispose();
  }

  Future<void> _checkAuthMethods() async {
    final methods = await _authService.getAvailableAuthMethods();
    setState(() {
      _authMethods = methods;
    });
  }

  void _initLedger() {
    try {
      final options = LedgerOptions(
        maxScanDuration: const Duration(milliseconds: 5000),
      );

      _ledger = Ledger(
        options: options,
        onPermissionRequest: (status) async {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.location,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ].request();

          if (status != BleStatus.ready) {
            setState(() => _error = 'Bluetooth is not ready');
            return false;
          }

          if (statuses.values.where((status) => status.isDenied).isNotEmpty) {
            setState(() => _error = 'Required permissions were denied');
            return false;
          }

          return true;
        },
      );
    } catch (e) {
      setState(() => _error = 'Failed to initialize Ledger: $e');
    }
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
      _error = null;
    });

    try {
      if (Platform.isAndroid) {
        List<LedgerDevice> devices = await _ledger.listUsbDevices();
        if (devices.isNotEmpty) {
          setState(() => _devices = devices);
        }
      }

      _ledger.scan().listen(
        (device) {
          setState(() => _devices.add(device));
        },
        onDone: () {
          setState(() => _isScanning = false);
        },
        onError: (e) {
          setState(() {
            _isScanning = false;
            _error = 'Scanning error: $e';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
        _error = 'Failed to start scanning: $e';
      });
    }
  }

  Future<void> _selectDevice(int index) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      LedgerDevice device = _devices[index];
      await _ledger.connect(device);

      _showConnectDialog();
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: '',
                  onBackPressed: () => Navigator.pop(context),
                  actionIcon: SvgPicture.asset(
                    'assets/icons/reload.svg',
                    width: 30,
                    height: 30,
                    colorFilter: ColorFilter.mode(
                      theme.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onActionPressed: _startScanning,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _isScanning
                            ? 'Looking for devices'
                            : 'Available devices',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isScanning
                            ? 'Please make sure your Ledger device is unlocked'
                            : _devices.isEmpty
                                ? 'No devices found. Pull to refresh or tap reload'
                                : 'Select a device to connect',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w100,
                          color: theme.textSecondary,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _startScanning,
                    child: ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        String icon =
                            device.connectionType == ConnectionType.usb
                                ? "assets/icons/usb.svg"
                                : "assets/icons/ble.svg";

                        return Column(
                          children: [
                            LedgerItem(
                              onTap: _isConnecting
                                  ? null
                                  : () {
                                      setState(() => _selected = index);
                                      _selectDevice(index);
                                    },
                              isLoading: _isConnecting && _selected == index,
                              icon: SvgPicture.asset(
                                icon,
                                width: 30,
                                height: 30,
                                color: theme.textPrimary,
                              ),
                              title: device.name,
                              id: device.id,
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConnectDialog() {
    LedgerDevice device = _devices[_selected];
    AuthMethod preferredAuth = _authMethods.contains(AuthMethod.none)
        ? AuthMethod.none
        : _authMethods[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => LedgerConnectDialog(
        walletName: device.name,
        biometricType: preferredAuth,
        onClose: () => Navigator.pop(context),
        onConnect: (int index, String name, bool useBiometric) async {
          if (useBiometric) {
            final authenticated = await _authService.authenticate(
              allowPinCode: true,
              reason: 'Please authenticate to enable quick access',
            );

            if (!authenticated) {
              throw "Fail biometric";
            }
          }

          LedgerDevice ledgerDevice = _devices[_selected];
          ZilliqaLedgerApp ledgerZilliqa = ZilliqaLedgerApp(_ledger);

          ({String publicKey, String address}) key =
              await ledgerZilliqa.getPublicAddress(ledgerDevice, index);

          DeviceInfoService device = DeviceInfoService();
          List<String> identifiers = await device.getDeviceIdentifiers();

          (String, String) session = await addLedgerZilliqaWallet(
            pubKey: key.publicKey,
            walletIndex: BigInt.from(index),
            walletName: name,
            ledgerId: ledgerDevice.id,
            accountName: "Ledger $index",
            biometricType:
                useBiometric ? preferredAuth.name : AuthMethod.none.name,
            identifiers: identifiers,
          );

          await _appState.syncData();
          _appState.setSelectedWallet(_appState.wallets.length - 1);
          await _authGuard.setSession(session.$2, session.$1);

          Navigator.of(context).pushNamed(
            '/',
          );
        },
      ),
    );
  }
}
