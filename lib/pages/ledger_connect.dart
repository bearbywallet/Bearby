import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/ledger_item.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/theme_provider.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  late AuthGuard _authGuard;
  late AppState _appState;

  final _btnController = RoundedLoadingButtonController();

  List<LedgerDevice> _devices = [];
  bool _isScanning = false;
  int _selected = -1;

  @override
  void initState() {
    super.initState();
    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);

    _startScanning();
  }

  @override
  void dispose() {
    _btnController.dispose();

    super.dispose();
  }

  Future<void> _startScanning() async {
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      final options = LedgerOptions(
        maxScanDuration: const Duration(
          milliseconds: 5000,
        ),
      );

      final ledger = Ledger(
        options: options,
        onPermissionRequest: (status) async {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.location,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ].request();

          if (status != BleStatus.ready) {
            return false;
          }

          return statuses.values.where((status) => status.isDenied).isEmpty;
        },
      );

      ledger.scan().listen((device) {
        setState(() {
          _devices.add(device);
        });
      }, onDone: () {
        setState(() {
          _isScanning = false;
        });
      }, onError: (e) {
        print("scan error $e");

        setState(() {
          _isScanning = false;
        });
      });
    } catch (e) {
      print("scan error $e");
      setState(() {
        _isScanning = false;
      });
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
                    onActionPressed: () {
                      _startScanning();
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Looking for devices',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please make sure your Ledger device is unlocked',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w100,
                            color: theme.textSecondary,
                          ),
                        ),
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
                          String icon = "assets/icons/ble.svg";

                          if (device.connectionType == ConnectionType.usb) {
                            icon = "assets/icons/usb.svg";
                          }

                          if (device.connectionType == ConnectionType.ble) {
                            icon = "assets/icons/ble.svg";
                          }

                          return Column(
                            children: [
                              LedgerItem(
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
