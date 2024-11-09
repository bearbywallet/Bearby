import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/ledger_item.dart';
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
  List<LedgerDevice> _devices = [];
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);
    _startScanning();
  }

  Future<void> _startScanning() async {
    try {
      final options = LedgerOptions(
        maxScanDuration: const Duration(milliseconds: 5000),
      );

      final ledger = Ledger(options: options);

      ledger.scan().listen(
        (device) {
          setState(() {
            _devices.add(device);
          });
        },
        onDone: () {
          setState(() {
            _isScanning = false;
          });
        },
      );
    } catch (e) {
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
                      print("reload ledgers");
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
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
                            'Pleas make sure your Ledger device is unlocked',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w100,
                              color: theme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LedgerItem(
                            icon: SvgPicture.asset(
                              "assets/icons/usb.svg",
                              width: 30,
                              height: 30,
                              color: theme.textPrimary,
                            ),
                            title: 'Nano x',
                            id: 'D41FB1B2-7549-8B25-803C...',
                          ),
                          const SizedBox(height: 8),
                          LedgerItem(
                            icon: SvgPicture.asset(
                              "assets/icons/ble.svg",
                              width: 30,
                              height: 30,
                              color: theme.textPrimary,
                            ),
                            title: 'Nano x',
                            id: 'D41FB1B2-7549-8B25-803C...',
                          ),
                        ],
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
