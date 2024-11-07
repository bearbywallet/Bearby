import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/state/app_state.dart' show AppState;
import '../theme/theme_provider.dart';

class LedgerConnectPage extends StatefulWidget {
  const LedgerConnectPage({super.key});

  @override
  State<LedgerConnectPage> createState() => _LedgerConnectPageState();
}

class _LedgerConnectPageState extends State<LedgerConnectPage> {
  late AuthGuard _authGuard;
  late AppState _appState;

  String _errorMessage = '';
  bool _disabled = false;
  bool _focused = false;

  final _btnController = RoundedLoadingButtonController();
  final _walletNameController = TextEditingController();
  final _walletNameKey = GlobalKey<SmartInputState>();

  @override
  void initState() {
    super.initState();
    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);
    _walletNameController.text = 'Ledger ${_appState.wallets.length + 1}';
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    if (_walletNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Wallet name cannot be empty';
        _disabled = false;
      });
      return false;
    }

    if (_walletNameController.text.length > 24) {
      setState(() {
        _errorMessage = 'Wallet name is too long';
        _disabled = false;
      });
      return false;
    }

    return true;
  }

  Future<void> _connectLedger() async {
    setState(() {
      _errorMessage = '';
      _disabled = true;
    });

    if (!_validateInput()) {
      _btnController.reset();
      return;
    }

    try {
      _btnController.start();

      DeviceInfoService device = DeviceInfoService();
      List<String> identifiers = await device.getDeviceIdentifiers();

      // TODO: Replace with actual Ledger connection logic
      // (String, String) session = await connectLedger(
      //   walletName: _walletNameController.text,
      //   identifiers: identifiers,
      // );

      // await _appState.syncData();

      _btnController.success();

      Navigator.of(context).pushNamed('/');
    } catch (e) {
      setState(() {
        _disabled = false;
        _errorMessage = e.toString();
      });
      _btnController.error();

      Timer(const Duration(seconds: 1), () {
        _btnController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final screenWidth = MediaQuery.of(context).size.width;
    const inputHeight = 50.0;

    final shouldHideButton = screenWidth <= 480 && _focused;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  children: [
                    CustomAppBar(
                      title: 'Connect Ledger',
                      onBackPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.all(adaptivePadding),
                                child: Column(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/ledger.svg',
                                      width: 64,
                                      height: 64,
                                      colorFilter: ColorFilter.mode(
                                        theme.primaryPurple,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Connect your Ledger device',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Make sure your Ledger is connected and unlocked',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: adaptivePadding * 2),
                              SmartInput(
                                key: _walletNameKey,
                                controller: _walletNameController,
                                hint: "Wallet Name",
                                fontSize: 18,
                                height: inputHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                focusedBorderColor: theme.primaryPurple,
                                disabled: _disabled,
                                onFocusChanged: (isFocused) {
                                  setState(() {
                                    _focused = isFocused;
                                  });
                                },
                                onChanged: (value) {
                                  if (_errorMessage.isNotEmpty) {
                                    setState(() => _errorMessage = '');
                                  }
                                },
                              ),
                              if (_errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: theme.danger,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!shouldHideButton)
                      Padding(
                        padding: EdgeInsets.only(bottom: adaptivePadding),
                        child: RoundedLoadingButton(
                          controller: _btnController,
                          onPressed: _connectLedger,
                          successIcon: SvgPicture.asset(
                            'assets/icons/ok.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              theme.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                          child: Text(
                            'Connect',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
