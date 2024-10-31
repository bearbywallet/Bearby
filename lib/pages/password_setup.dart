import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import '../theme/theme_provider.dart';

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  final _btnController = RoundedLoadingButtonController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _confirmPasswordInputKey = GlobalKey<SmartInputState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _useBiometric = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePasswords() {
    if (_passwordController.text.length < 8) {
      _passwordInputKey.currentState?.shake();
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordInputKey.currentState?.shake();
      return false;
    }

    return true;
  }

  void _createWallet() async {
    if (!_validatePasswords()) {
      _btnController.reset();
      return;
    }

    _btnController.start();
    try {
      Timer(const Duration(seconds: 5), () {
        _btnController.success();
      });
    } catch (e) {
      _btnController.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
            child: Column(
              children: [
                CustomAppBar(
                  title: '',
                  onBackPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create Password',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your password must be at least 8 characters',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SmartInput(
                            key: _passwordInputKey,
                            controller: _passwordController,
                            hint: "Password",
                            fontSize: 18,
                            height: 56,
                            borderColor: theme.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            focusedBorderColor: theme.primaryPurple,
                            obscureText: _obscurePassword,
                            rightIconPath: _obscurePassword
                                ? "assets/icons/close_eye.svg"
                                : "assets/icons/open_eye.svg",
                            onSubmitted: () {},
                            onRightIconTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SmartInput(
                            key: _confirmPasswordInputKey,
                            controller: _confirmPasswordController,
                            hint: "Confirm Password",
                            height: 56,
                            fontSize: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            obscureText: _obscureConfirmPassword,
                            rightIconPath: _obscureConfirmPassword
                                ? "assets/icons/close_eye.svg"
                                : "assets/icons/open_eye.svg",
                            onRightIconTap: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          // Biometric option with Switch
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Enable Face ID / Touch ID',
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                Switch(
                                  value: _useBiometric,
                                  onChanged: (value) {
                                    setState(() {
                                      _useBiometric = value;
                                    });
                                  },
                                  activeColor: theme.primaryPurple,
                                  activeTrackColor:
                                      theme.primaryPurple.withOpacity(0.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom button
                Padding(
                  padding: EdgeInsets.only(
                      bottom: adaptivePadding,
                      left: adaptivePadding,
                      right: adaptivePadding),
                  child: RoundedLoadingButton(
                    controller: _btnController,
                    onPressed: _createWallet,
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
                      'Create Password',
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
    );
  }
}
