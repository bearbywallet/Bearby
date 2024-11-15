import 'dart:async';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/biometric_switch.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/state/app_state.dart' show AppState;
import '../theme/theme_provider.dart';

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  List<String>? _bip39List;
  List<int>? _codes;
  int? _cipher;
  KeyPair? _keys;

  final AuthService _authService = AuthService();
  late AuthGuard _authGuard;
  late AppState _appState;

  List<AuthMethod> _authMethods = [AuthMethod.none];
  bool _useDeviceAuth = false;

  String _errorMessage = '';
  bool _disabled = false;
  bool _focused = false;

  final _btnController = RoundedLoadingButtonController();

  final _walletNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _confirmPasswordInputKey = GlobalKey<SmartInputState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final codes = args?['codes'] as List<int>?;
    final int? cipher = args?['cipher'];
    final keys = args?['keys'] as KeyPair?;

    if (bip39 == null && codes == null && cipher == null && keys == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _codes = codes;
        _cipher = cipher;
        _keys = keys;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);

    _walletNameController.text = 'Wallet ${_appState.wallets.length + 1}';

    _checkAuthMethods();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _walletNameController.dispose();
    _btnController.dispose();

    super.dispose();
  }

  bool _validatePasswords() {
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

    if (_passwordController.text.length < 6) {
      _passwordInputKey.currentState?.shake();

      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
        _disabled = false;
      });

      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordInputKey.currentState?.shake();

      setState(() {
        _disabled = false;
        _errorMessage = 'Passwords do not match';
      });

      return false;
    }

    return true;
  }

  void _createWallet() async {
    setState(() {
      _errorMessage = '';
      _disabled = true;
    });

    if (!_validatePasswords()) {
      _btnController.reset();
      return;
    }

    try {
      if (_useDeviceAuth) {
        final authenticated = await _authService.authenticate(
          allowPinCode: true,
          reason: 'Please authenticate to enable quick access',
        );

        setState(() => _useDeviceAuth = authenticated);

        if (!authenticated) {
          setState(() {
            _disabled = true;
          });

          return;
        }
      }

      _btnController.start();

      Uint64List networkIndexes = Uint64List.fromList(_codes!);
      Uint64List accountsIndexes =
          Uint64List.fromList([0]); // TODO: maybe make ui/ux

      DeviceInfoService device = DeviceInfoService();
      List<String> identifiers = await device.getDeviceIdentifiers();

      AuthMethod biometricType = AuthMethod.none;

      if (_useDeviceAuth) {
        biometricType = _authMethods[0];
      }

      (String, String) session;

      if (_bip39List != null) {
        session = await addBip39Wallet(
          password: _passwordController.text,
          mnemonicStr: _bip39List!.join(' '),
          indexes: accountsIndexes,
          passphrase: "", // TODO: maybe make it
          walletName: _walletNameController.text,
          biometricType: biometricType.name,
          netCodes: networkIndexes,
          identifiers: identifiers,
        );
      } else if (_keys != null) {}

      if (_useDeviceAuth) {
        await _authGuard.setSession(session.$2, session.$1);
      }

      await _appState.syncData();

      _btnController.success();

      Navigator.of(context).pushNamed(
        '/',
      );
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
                      title: '',
                      onBackPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
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
                              SizedBox(height: adaptivePadding),
                              SmartInput(
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
                                  if (_errorMessage != '') {
                                    setState(() {
                                      _errorMessage = '';
                                    });
                                  }
                                },
                              ),
                              SizedBox(height: adaptivePadding),
                              SmartInput(
                                key: _passwordInputKey,
                                controller: _passwordController,
                                hint: "Password",
                                fontSize: 18,
                                height: inputHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                focusedBorderColor: theme.primaryPurple,
                                disabled: _disabled,
                                obscureText: _obscurePassword,
                                rightIconPath: _obscurePassword
                                    ? "assets/icons/close_eye.svg"
                                    : "assets/icons/open_eye.svg",
                                onChanged: (value) {
                                  if (_errorMessage != '') {
                                    setState(() {
                                      _errorMessage = '';
                                    });
                                  }
                                },
                                onFocusChanged: (isFocused) {
                                  setState(() {
                                    _focused = isFocused;
                                  });
                                },
                                onRightIconTap: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              SizedBox(height: adaptivePadding),
                              SmartInput(
                                key: _confirmPasswordInputKey,
                                controller: _confirmPasswordController,
                                hint: "Confirm Password",
                                height: inputHeight,
                                fontSize: 18,
                                disabled: _disabled,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
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
                                onFocusChanged: (isFocused) {
                                  setState(() {
                                    _focused = isFocused;
                                  });
                                },
                                onChanged: (value) {
                                  if (_errorMessage != '') {
                                    setState(() {
                                      _errorMessage = '';
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: theme.danger,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              BiometricSwitch(
                                biometricType: _authMethods.first,
                                value: _useDeviceAuth,
                                disabled: _disabled,
                                onChanged: (value) async {
                                  setState(() => _useDeviceAuth = value);
                                },
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
        ),
      ),
    );
  }

  Future<void> _checkAuthMethods() async {
    final methods = await _authService.getAvailableAuthMethods();
    setState(() {
      _authMethods = methods;
    });
  }
}
