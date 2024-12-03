import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/custom_app_bar.dart';
import '../../components/smart_input.dart';
import '../../theme/theme_provider.dart';

class AddNextBip39AccountContent extends StatefulWidget {
  final VoidCallback onBack;

  const AddNextBip39AccountContent({
    super.key,
    required this.onBack,
  });

  @override
  State<AddNextBip39AccountContent> createState() =>
      _AddNextBip39AccountContentState();
}

class _AddNextBip39AccountContentState
    extends State<AddNextBip39AccountContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _passwordController = TextEditingController();
  late AppState _appState;

  bool _obscurePassword = true;
  bool _obscurePassphrase = true;
  String _errorMessage = '';

  final _nameInputKey = GlobalKey<SmartInputState>();
  final _passphraseInputKey = GlobalKey<SmartInputState>();
  final _passwordInputKey = GlobalKey<SmartInputState>();

  @override
  void dispose() {
    _nameController.dispose();
    _passphraseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);

    print(_appState.wallet!.authType);
    _nameController.text = 'Account ${_appState.wallet!.accounts.length + 1}';
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _nameInputKey.currentState?.shake();
      setState(() => _errorMessage = 'Please enter account name');
      return false;
    }

    if (_passphraseController.text.trim().isEmpty) {
      _passphraseInputKey.currentState?.shake();
      setState(() => _errorMessage = 'Please enter passphrase');
      return false;
    }

    if (_passwordController.text.length < 8) {
      _passwordInputKey.currentState?.shake();
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const inputHeight = 50.0;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAppBar(
          title: '',
          onBackPressed: widget.onBack,
          actionText: 'Create',
          onActionPressed: () {
            setState(() => _errorMessage = '');
            if (_validateForm()) {
              // Handle account creation
              // Access values using controllers:
              // _nameController.text
              // _passphraseController.text
              // _passwordController.text
            }
          },
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 0,
              bottom: bottomInset > 0 ? bottomInset + 40.0 : 40.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SmartInput(
                    key: _nameInputKey,
                    controller: _nameController,
                    hint: "Enter account name",
                    height: inputHeight,
                    fontSize: 18,
                    focusedBorderColor: theme.primaryPurple,
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    onChanged: (value) => setState(() => _errorMessage = ''),
                  ),
                  SizedBox(height: adaptivePadding),
                  SmartInput(
                    key: _passphraseInputKey,
                    controller: _passphraseController,
                    hint: "Enter passphrase",
                    height: inputHeight,
                    fontSize: 18,
                    obscureText: _obscurePassphrase,
                    focusedBorderColor: theme.primaryPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    rightIconPath: _obscurePassphrase
                        ? "assets/icons/close_eye.svg"
                        : "assets/icons/open_eye.svg",
                    onRightIconTap: () => setState(
                        () => _obscurePassphrase = !_obscurePassphrase),
                    onChanged: (value) => setState(() => _errorMessage = ''),
                  ),
                  if (_appState.wallet!.authType == AuthMethod.none.name) ...[
                    SizedBox(height: adaptivePadding),
                    SmartInput(
                      key: _passwordInputKey,
                      controller: _passwordController,
                      hint: "Enter password",
                      height: inputHeight,
                      fontSize: 18,
                      obscureText: _obscurePassword,
                      focusedBorderColor: theme.primaryPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      rightIconPath: _obscurePassword
                          ? "assets/icons/close_eye.svg"
                          : "assets/icons/open_eye.svg",
                      onRightIconTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onChanged: (value) => setState(() => _errorMessage = ''),
                    )
                  ],
                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: adaptivePadding),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: theme.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
