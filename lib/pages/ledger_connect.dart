import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  final _btnController = RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  Future<void> _checkAuthMethods() async {}

  void _initLedger() {}

  Future<void> _startScanning() async {}

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;

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
                    children: [],
                  ),
                ),
                const SizedBox(height: 16),
                // Expanded(
                //   child: RefreshIndicator(
                //     onRefresh: _startScanning,
                //     child: ListView.builder(
                //       padding:
                //           EdgeInsets.symmetric(horizontal: adaptivePadding),
                //       itemCount: _devices.length,
                //       itemBuilder: (context, index) {},
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
