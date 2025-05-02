import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:zilpay/components/async_qrcode.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/hex_key.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/qrcode.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

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

  @override
  void initState() {
    _secureScreen();
    super.initState();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageOff();
    ScreenProtector.protectDataLeakageWithBlurOff();
    super.dispose();
  }

  Future<void> _secureScreen() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  void _onPasswordSubmit(BigInt walletIndex, BigInt accountIndex) async {
    final l10n = AppLocalizations.of(context)!;

    _btnController.start();
    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      await tryUnlockWithPassword(
        password: _passwordController.text,
        walletIndex: walletIndex,
        identifiers: identifiers,
      );
      KeyPairInfo keypair = await revealKeypair(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        identifiers: identifiers,
        password: _passwordController.text,
      );

      setState(() {
        keys = keypair;
        isAuthenticated = true;
        hasError = false;
        errorMessage = null;
      });
      _btnController.success();
    } catch (e) {
      setState(() {
        isAuthenticated = false;
        hasError = true;
        errorMessage = "${l10n.revealSecretKeyInvalidPassword} $e";
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: l10n.revealSecretKeyTitle,
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
                        hint: l10n.revealSecretKeyPasswordHint,
                        fontSize: 18,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        focusedBorderColor: theme.primaryPurple,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _onPasswordSubmit(
                          BigInt.from(state.selectedWallet),
                          state.wallet!.selectedAccount,
                        ),
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
                          color: theme.primaryPurple,
                          valueColor: theme.buttonText,
                          controller: _btnController,
                          onPressed: () => _onPasswordSubmit(
                            BigInt.from(state.selectedWallet),
                            state.wallet!.selectedAccount,
                          ),
                          child: Text(
                            l10n.revealSecretKeySubmitButton,
                            style: TextStyle(
                              color: theme.buttonText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isAuthenticated) ...[
                      if (keys != null) ...[
                        _buildQrCode(theme),
                        HexKeyDisplay(
                          hexKey: keys!.sk,
                          title: "",
                        )
                      ],
                      SizedBox(height: adaptivePadding),
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
                        onPressed: () => _handleCopy(keys?.sk ?? ""),
                        backgroundColor: theme.cardBackground,
                        textColor: theme.primaryPurple,
                      ),
                      SizedBox(height: adaptivePadding),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: EdgeInsets.only(bottom: adaptivePadding),
                        child: CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: l10n.revealSecretKeyDoneButton,
                          onPressed: () => Navigator.pop(context),
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.danger.withValues(alpha: 0.1),
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
                l10n.revealSecretKeyScamAlertTitle,
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
            l10n.revealSecretKeyScamAlertMessage,
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
    final state = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final chain = state.chain!;

    return Container(
      margin: EdgeInsets.symmetric(vertical: adaptivePadding),
      child: Center(
        child: AsyncQRcode(
          data: generateQRSecretData(
            chain: chain.shortName,
            privateKey: keys?.sk,
          ),
          size: 160,
          color: theme.danger,
          eyeShape: EyeShape.circle,
          dataModuleShape: DataModuleShape.circle,
          loadingWidget: CircularProgressIndicator(
            color: theme.danger,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCopy(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    setState(() {
      isCopied = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    setState(() {
      isCopied = false;
    });
  }
}
