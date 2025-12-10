import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
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

class _KeystoreBackupState extends State<KeystoreBackup> with StatusBarMixin {
  bool isProcessing = false;
  bool hasError = false;
  String? errorMessage;
  bool _obscureConfirmPassword = true;
  bool isBackupCreated = false;
  String? backupFilePath;
  Uint8List? keystoreBytes;

  final _noScreenshot =
      Platform.isIOS || Platform.isAndroid ? NoScreenshot.instance : null;
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
    _noScreenshot?.screenshotOn();
    super.dispose();
  }

  Future<void> _secureScreen() async {
    if (_noScreenshot != null) {
      await _noScreenshot.screenshotOff();
    }
  }

  void _onCreateBackup(BigInt walletIndex, String name) async {
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

      keystoreBytes = await makeKeystoreFile(
        walletIndex: walletIndex,
        password: _confirmPasswordController.text,
        deviceIndicators: identifiers,
      );

      final docPath = await _saveKeystoreToDocumentsDir(
        keystoreBytes!,
        name,
      );

      setState(() {
        isBackupCreated = true;
        backupFilePath = docPath;
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

  Future<String> _saveKeystoreToDocumentsDir(
    Uint8List keystoreBytes,
    String name,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${directory.path}/${name}_zilpay_keystore_$timestamp.zp';

      final file = File(filePath);
      await file.writeAsBytes(keystoreBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save keystore file: $e');
    }
  }

  Future<void> _saveKeystoreWithPicker(String name) async {
    final l10n = AppLocalizations.of(context)!;

    if (keystoreBytes == null) {
      setState(() {
        hasError = true;
        errorMessage = l10n.keystoreBackupError;
      });
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${name}_zilpay_keystore_$timestamp.zp';

      if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        final outputPath = '${directory.path}/$fileName';

        final file = File(outputPath);
        await file.writeAsBytes(keystoreBytes!);

        setState(() {
          backupFilePath = outputPath;
        });

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(outputPath)],
          ),
        );
      } else {
        String? outputDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: l10n.keystoreBackupSaveDialogTitle,
        );

        if (outputDirectory != null) {
          final outputPath = '$outputDirectory/$fileName';

          final file = File(outputPath);
          await file.writeAsBytes(keystoreBytes!);

          setState(() {
            backupFilePath = outputPath;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.keystoreBackupSavedSuccess),
                backgroundColor: Provider.of<AppState>(context, listen: false)
                    .currentTheme
                    .success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = '${l10n.keystoreBackupSaveFailed}: $e';
        });
      }
    }
  }

  Future<void> _shareKeystoreFile() async {
    if (backupFilePath == null || !File(backupFilePath!).existsSync()) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.keystoreBackupSaveFailed),
          backgroundColor:
              Provider.of<AppState>(context, listen: false).currentTheme.danger,
        ),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backupFilePath!)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = state.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
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
                    if (!isBackupCreated) ...[
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
                          BigInt.from(
                            state.selectedWallet,
                          ),
                          state.wallet?.walletName ?? "",
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
                            style: theme.bodyText2.copyWith(
                              color: theme.danger,
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
                            state.wallet?.walletName ?? "",
                          ),
                          child: Text(
                            l10n.keystoreBackupCreateButton,
                            style: theme.titleSmall.copyWith(
                              color: theme.buttonText,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isBackupCreated) ...[
                      _buildSuccessMessage(theme),
                      SizedBox(height: adaptivePadding),
                      if (!Platform.isIOS) ...[
                        Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: l10n.keystoreBackupSaveAsButton,
                            onPressed: () => _saveKeystoreWithPicker(
                              state.wallet?.walletName ?? "",
                            ),
                            borderRadius: 30.0,
                            height: 56.0,
                          ),
                        ),
                        SizedBox(height: adaptivePadding),
                      ],
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
                          backgroundColor: theme.secondaryPurple,
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
                style: theme.bodyLarge.copyWith(
                  color: theme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.keystoreBackupWarningMessage,
            style: theme.bodyText2.copyWith(
              color: theme.warning,
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
                style: theme.bodyLarge.copyWith(
                  color: theme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.keystoreBackupSuccessMessage,
            style: theme.bodyText2.copyWith(
              color: theme.success,
            ),
          ),
          if (backupFilePath != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.keystoreBackupTempLocation}:\n$backupFilePath',
              style: theme.labelSmall.copyWith(
                color: theme.success,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
