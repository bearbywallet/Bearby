import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/hex_key.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class RevealSecretKey extends StatefulWidget {
  const RevealSecretKey({super.key});

  @override
  State<RevealSecretKey> createState() => _RevealSecretKeyState();
}

class _RevealSecretKeyState extends State<RevealSecretKey> {
  bool isCopied = false;
  bool isAuthenticated = false;
  bool hasError = false;
  String? errorMessage;
  bool _obscurePassword = true;
  KeyPairInfo? keys;

  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  void _onPasswordSubmit(BigInt walletIndex) async {
    _btnController.start();
    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      await tryUnlockWithPassword(
        password: _passwordController.text,
        walletIndex: walletIndex,
        identifiers: identifiers,
      );

      setState(() {
        isAuthenticated = true;
        hasError = false;
        errorMessage = null;
      });
      _btnController.success();
    } catch (e) {
      setState(() {
        isAuthenticated = false;
        hasError = true;
        errorMessage = "invalid password, error: $e";
      });
      _btnController.error();
      await Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = state.currentTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Reveal Secret Key',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  children: [
                    _buildScamAlert(theme),
                    if (!isAuthenticated) ...[
                      SmartInput(
                        key: _passwordInputKey,
                        controller: _passwordController,
                        hint: "Password",
                        fontSize: 18,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        focusedBorderColor: theme.primaryPurple,
                        obscureText: _obscurePassword,
                        onSubmitted: () => _onPasswordSubmit(
                            BigInt.from(state.selectedWallet)),
                        rightIconPath: _obscurePassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      if (hasError && errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: theme.danger,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: RoundedLoadingButton(
                          controller: _btnController,
                          onPressed: () => _onPasswordSubmit(
                              BigInt.from(state.selectedWallet)),
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
                            'Submit',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isAuthenticated) ...[
                      _buildQrCode(theme),
                      HexKeyDisplay(
                        hexKey: '',
                        title: "Private Key",
                      ),
                      const SizedBox(height: 16),
                      TileButton(
                        icon: SvgPicture.asset(
                          isCopied
                              ? "assets/icons/check.svg"
                              : "assets/icons/copy.svg",
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            theme.primaryPurple,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () => _handleCopy(''),
                        backgroundColor: theme.cardBackground,
                        textColor: theme.primaryPurple,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: EdgeInsets.only(bottom: adaptivePadding),
                        child: CustomButton(
                          text: 'Done',
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: theme.primaryPurple,
                          borderRadius: 30.0,
                          height: 56.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScamAlert(AppTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.danger),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.danger,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'SCAM ALERT',
                style: TextStyle(
                  color: theme.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Never share your secret key with anyone. Never input it on any website.',
            style: TextStyle(
              color: theme.danger,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode(AppTheme theme) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'QR Code',
          style: TextStyle(
            color: theme.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCopy(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    setState(() {
      isCopied = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    setState(() {
      isCopied = false;
    });
  }
}
