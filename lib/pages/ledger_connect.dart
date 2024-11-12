import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zilliqa_ledger_flutter/zilliqa_ledger_flutter.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/ledger_item.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import '../theme/theme_provider.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  late Ledger _ledger;

  final _btnController = RoundedLoadingButtonController();

  List<LedgerDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  int _selected = -1;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLedger();

      Future.delayed(const Duration(milliseconds: 1000), () {
        _startScanning();
      });
    });
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
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

      ZilliqaLedgerApp ledgerZilliqa = ZilliqaLedgerApp(_ledger);
      ZilliqaVersion version = await ledgerZilliqa.getVersion(device);
      print(version.toString());
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
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  CustomAppBar(
                    title: '',
                    onBackPressed: () => Navigator.pop(context),
                    actionIconPath: 'assets/icons/reload.svg',
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
      ),
    );
  }
}
