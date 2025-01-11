import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/biometric_switch.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/config/argon.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart' show AppState;

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  List<String>? _bip39List;
  int? _provider;
  WalletArgonParamsInfo? _argon2;
  Uint8List? _cipher;
  KeyPairInfo? _keys;

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
    final provider = args?['provider'] as int?;
    final keys = args?['keys'] as KeyPairInfo?;
    final cipher = args?['cipher'] as Uint8List?;
    final argon2 = args?['argon2'] as WalletArgonParamsInfo?;

    if (bip39 == null && provider == null && cipher == null && keys == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _provider = provider;
        _keys = keys;
        _cipher = cipher;
        _argon2 = argon2;
      });
    }

    // Set wallet name based on type
    if (bip39 != null) {
      _walletNameController.text =
          'Seed Wallet ${_appState.wallets.length + 1}';
    } else if (keys != null) {
      _walletNameController.text = 'Key Wallet ${_appState.wallets.length + 1}';
    } else {
      _walletNameController.text = 'Wallet ${_appState.wallets.length + 1}';
    }
  }

  @override
  void initState() {
    super.initState();

    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);

    if (_bip39List != null) {
      _walletNameController.text =
          'Seed Wallet ${_appState.wallets.length + 1}';
    } else if (_keys != null) {
      _walletNameController.text = 'Key Wallet ${_appState.wallets.length + 1}';
    } else {
      _walletNameController.text = 'Wallet ${_appState.wallets.length + 1}';
    }

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

      DeviceInfoService device = DeviceInfoService();
      List<String> identifiers = await device.getDeviceIdentifiers();

      AuthMethod biometricType = AuthMethod.none;

      if (_useDeviceAuth) {
        biometricType = _authMethods[0];
      }

      (String, String) session;

      WalletSettingsInfo settings = WalletSettingsInfo(
        cipherOrders: _cipher!,
        argonParams: _argon2!,
        currencyConvert: "BTC",
        ipfsNode: "dweb.link",
        ensEnabled: true,
        gasControlEnabled: true,
        nodeRankingEnabled: true,
        maxConnections: 5,
        requestTimeoutSecs: 30,
      );
      FTokenInfo ftoken = DefaultTokens.defaultFtokens()[_provider!];

      if (_bip39List != null) {
        Bip39AddWalletParams params = Bip39AddWalletParams(
          password: _passwordController.text,
          mnemonicStr: _bip39List!.join(' '),
          accounts: [
            (BigInt.zero, "Account 0")
          ], // TODO: add interface for change Account name
          passphrase: "", // TODO: maybe make it
          walletName: _walletNameController.text,
          biometricType: biometricType.name,
          identifiers: identifiers,
          provider: BigInt.from(_provider!),
        );

        session = await addBip39Wallet(
          params: params,
          walletSettings: settings,
          ftokens: [ftoken],
        );
      } else if (_keys != null) {
        AddSKWalletParams params = AddSKWalletParams(
          sk: _keys!.sk,
          password: _passwordController.text,
          walletName: _walletNameController.text,
          biometricType: biometricType.name,
          identifiers: identifiers,
          provider: BigInt.from(_provider!),
        );

        session = await addSkWallet(
          params: params,
          walletSettings: settings,
          ftokens: [ftoken],
        );
      } else {
        throw "Invalid Wallet gen method";
      }

      if (_useDeviceAuth) {
        await _authGuard.setSession(session.$2, session.$1);
      }

      await _appState.syncData();
      _appState.setSelectedWallet(_appState.wallets.length - 1);
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
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final screenWidth = MediaQuery.of(context).size.width;
    const inputHeight = 50.0;

    final shouldHideButton = screenWidth <= 480 && _focused;

    return Scaffold(
      body: SafeArea(
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
    );
  }

  Future<void> _checkAuthMethods() async {
    final methods = await _authService.getAvailableAuthMethods();
    setState(() {
      _authMethods = methods;
    });
  }
}
