import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class RestoreKeystoreFilePage extends StatefulWidget {
  const RestoreKeystoreFilePage({super.key});

  @override
  State<RestoreKeystoreFilePage> createState() =>
      _RestoreKeystoreFilePageState();
}

class _RestoreKeystoreFilePageState extends State<RestoreKeystoreFilePage> {
  String _selectedFilePath = '';
  String _selectedFileName = '';
  String _password = '';
  bool _disabled = false;
  String _errorMessage = '';
  final TextEditingController _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _selectKeystoreFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path!;
          _selectedFileName = result.files.single.name;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _restoreFromKeystore() async {
    if (_selectedFilePath.isEmpty || _password.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.keystoreRestoreEmptyError;
      });
      return;
    }

    setState(() {
      _errorMessage = "";
    });

    try {
      // Call the Rust method to restore from keystore
      // final KeyPairInfo keys = await restoreFromKeystore(
      //   filePath: _selectedFilePath,
      //   password: _password,
      // );

      // if (mounted) {
      //   Navigator.of(context).pushReplacementNamed(
      //     '/home_page',
      //     arguments: {'keys': keys},
      //   );
      // }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: l10n.restoreWalletOptionsKeyStoreTitle,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            SvgPicture.asset(
                              'assets/icons/document.svg',
                              width: 80,
                              height: 80,
                              colorFilter: ColorFilter.mode(
                                theme.primaryPurple,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _selectedFileName.isEmpty
                                  ? l10n.keystoreNoFileSelected
                                  : _selectedFileName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: theme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (_selectedFilePath.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: SmartInput(
                                  key: _passwordInputKey,
                                  controller: _passwordController,
                                  hint: l10n.keystorePasswordHint,
                                  height: 50.0,
                                  fontSize: 18,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  focusedBorderColor: theme.primaryPurple,
                                  disabled: _disabled,
                                  obscureText: _obscurePassword,
                                  rightIconPath: _obscurePassword
                                      ? "assets/icons/close_eye.svg"
                                      : "assets/icons/open_eye.svg",
                                  onRightIconTap: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _password = value;
                                      if (_errorMessage != '') {
                                        _errorMessage = '';
                                      }
                                    });
                                  },
                                ),
                              ),
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: theme.danger,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomButton(
                                  textColor: theme.buttonText,
                                  backgroundColor: _selectedFilePath.isEmpty
                                      ? theme.primaryPurple
                                      : theme.secondaryPurple,
                                  text: _selectedFilePath.isEmpty
                                      ? l10n.keystoreSelectFileButton
                                      : l10n.keystoreChangeFileButton,
                                  onPressed: _selectKeystoreFile,
                                  borderRadius: 30.0,
                                  height: 56.0,
                                  disabled: _disabled,
                                ),
                                if (_selectedFilePath.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: RoundedLoadingButton(
                                      color: theme.primaryPurple,
                                      valueColor: theme.buttonText,
                                      controller: _btnController,
                                      onPressed: _password.isEmpty || _disabled
                                          ? null
                                          : _restoreFromKeystore,
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
                                        l10n.keystoreRestoreButton,
                                        style: TextStyle(
                                          color: theme.buttonText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
