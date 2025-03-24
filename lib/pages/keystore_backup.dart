import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class KeystoreBackup extends StatefulWidget {
  const KeystoreBackup({super.key});

  @override
  State<KeystoreBackup> createState() => _KeystoreBackupState();
}

class _KeystoreBackupState extends State<KeystoreBackup> {
  bool isProcessing = false;
  bool hasError = false;
  String? errorMessage;
  bool _obscureConfirmPassword = true;
  bool isBackupCreated = false;
  String? backupFilePath;

  final _confirmPasswordController = TextEditingController();
  final _confirmPasswordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  @override
  void initState() {
    _secureScreen();
    super.initState();
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
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

  void _onCreateBackup(BigInt walletIndex) async {
    final l10n = AppLocalizations.of(context)!;

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        hasError = true;
        errorMessage = l10n.keystoreBackupPasswordTooShort;
      });
      return;
    }

    _btnController.start();
    setState(() {
      isProcessing = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      // Simulate processing with 1-second delay
      await Future.delayed(const Duration(seconds: 1));

      await tryUnlockWithPassword(
        password: _confirmPasswordController.text,
        walletIndex: walletIndex,
        identifiers: identifiers,
      );

      // final keystore = await createKeystoreBackup(
      //   walletIndex: walletIndex,
      //   identifiers: identifiers,
      //   password: _confirmPasswordController.text,
      // );

      final path = await _saveKeystoreToFile("");

      setState(() {
        isBackupCreated = true;
        backupFilePath = path;
        isProcessing = false;
      });

      _btnController.success();
    } catch (e) {
      setState(() {
        isProcessing = false;
        hasError = true;
        errorMessage = "${l10n.keystoreBackupError} $e";
      });
      _btnController.error();
      await Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    }
  }

  Future<String> _saveKeystoreToFile(String keystoreJson) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/zilpay_keystore_$timestamp.json';

      final file = File(filePath);
      await file.writeAsString(keystoreJson);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save keystore file: $e');
    }
  }

  Future<void> _shareKeystoreFile() async {
    if (backupFilePath != null) {
      await Share.shareXFiles([XFile(backupFilePath!)]);
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
              title: l10n.keystoreBackupTitle,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  children: [
                    _buildWarningAlert(theme),
                    SmartInput(
                      key: _confirmPasswordInputKey,
                      controller: _confirmPasswordController,
                      hint: l10n.keystoreBackupConfirmPasswordHint,
                      fontSize: 18,
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      focusedBorderColor: theme.primaryPurple,
                      obscureText: _obscureConfirmPassword,
                      onSubmitted: (_) => _onCreateBackup(
                        BigInt.from(state.selectedWallet),
                      ),
                      rightIconPath: _obscureConfirmPassword
                          ? "assets/icons/close_eye.svg"
                          : "assets/icons/open_eye.svg",
                      onRightIconTap: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
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
                        onPressed: () => _onCreateBackup(
                          BigInt.from(state.selectedWallet),
                        ),
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
                          l10n.keystoreBackupCreateButton,
                          style: TextStyle(
                            color: theme.buttonText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isBackupCreated) ...[
                      _buildSuccessMessage(theme),
                      SizedBox(height: adaptivePadding),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: l10n.keystoreBackupShareButton,
                          onPressed: _shareKeystoreFile,
                          borderRadius: 30.0,
                          height: 56.0,
                        ),
                      ),
                      SizedBox(height: adaptivePadding),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: l10n.keystoreBackupDoneButton,
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

  Widget _buildWarningAlert(AppTheme theme) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.warning),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/icons/warning.svg",
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  theme.warning,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.keystoreBackupWarningTitle,
                style: TextStyle(
                  color: theme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.keystoreBackupWarningMessage,
            style: TextStyle(
              color: theme.warning,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(AppTheme theme) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.success),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.keystoreBackupSuccessTitle,
                style: TextStyle(
                  color: theme.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.keystoreBackupSuccessMessage,
            style: TextStyle(
              color: theme.success,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
