import 'dart:async';

import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/wallet_option.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/theme_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  final AuthService _authService = AuthService();

  late AuthGuard _authGuard;
  late AppState _appState;

  bool obscurePassword = true;
  bool obscureButton = true;
  int sellectedWallet = -1;

  @override
  void initState() {
    super.initState();

    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);
  }

  @override
  void dispose() {
    passwordController.dispose();
    _btnController.dispose();

    super.dispose();
  }

  Color _getWalletColor(int index) {
    final colors = [
      const Color(0xFF55A2F2),
      const Color(0xFFFFB347),
      const Color(0xFF4ECFB0),
    ];
    return colors[index % colors.length];
  }

  void toHome() {
    Navigator.of(context).pushNamed(
      '/',
    );
  }

  Future<void> walletTap(int index) async {
    final wallet = _appState.wallets[index];

    try {
      // if Ledger device
      if (wallet.walletType == 0 && wallet.authType == AuthMethod.none.name) {
        _authGuard.setEnabled(true);
        toHome();
        return;
      }

      if (wallet.authType != "none") {
        _btnController.start();

        final authenticated = await _authService.authenticate(
          allowPinCode: true,
          reason: 'Please authenticate',
        );

        if (!authenticated) {
          _btnController.error();

          Timer(const Duration(seconds: 1), () {
            _btnController.reset();
          });

          return;
        }

        String session =
            await _authGuard.getSession(sessionKey: wallet.walletAddress);

        DeviceInfoService device = DeviceInfoService();
        List<String> identifiers = await device.getDeviceIdentifiers();

        bool unlocked = await tryUnlockWithSession(
            sessionCipher: session,
            walletIndex: BigInt.from(index),
            identifiers: identifiers);

        if (unlocked) {
          _btnController.success();

          toHome();
        } else {
          _btnController.error();

          Timer(const Duration(seconds: 1), () {
            _btnController.reset();
          });
        }
      }
    } catch (e) {
      _btnController.error();

      Timer(const Duration(seconds: 1), () {
        _btnController.reset();
      });
    }
  }

  Future<void> unlock() async {
    final wallet = _appState.wallets[sellectedWallet];

    try {
      // if Ledger device
      if (wallet.walletType == 0 && wallet.authType == AuthMethod.none.name) {
        _authGuard.setEnabled(true);
        toHome();
        return;
      }

      if (passwordController.text.isNotEmpty) {
        DeviceInfoService device = DeviceInfoService();
        List<String> identifiers = await device.getDeviceIdentifiers();

        bool unlocked = await tryUnlockWithPassword(
            password: passwordController.text,
            walletIndex: BigInt.from(sellectedWallet),
            identifiers: identifiers);

        if (unlocked) {
          _btnController.success();

          return toHome();
        } else {
          _passwordInputKey.currentState?.shake();
          _btnController.reset();

          return;
        }
      }
    } catch (e) {
      if (passwordController.text.isNotEmpty) {
        _passwordInputKey.currentState?.shake();
      } else {
        _btnController.reset();
      }

      Timer(const Duration(seconds: 1), () {
        _btnController.reset();
      });
    }

    await walletTap(sellectedWallet);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final screenSize = MediaQuery.of(context).size;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Positioned(
            child: SizedBox(
              height: screenSize.height * 0.6,
              child: Transform.scale(
                scale: 1.4,
                child: SvgPicture.asset(
                  'assets/imgs/zilpay.svg',
                  fit: BoxFit.cover,
                  width: screenSize.width,
                  height: screenSize.height * 0.6,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/new_wallet_options');
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/plus.svg',
                              width: 32,
                              height: 32,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        itemCount: _appState.wallets.length,
                        itemBuilder: (context, index) {
                          final wallet = _appState.wallets[index];

                          if (!obscureButton && sellectedWallet != index) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: EdgeInsets.only(top: index > 0 ? 4 : 0),
                            child: WalletOption(
                              title: wallet.walletName.isEmpty
                                  ? "Wallet ${index + 1}"
                                  : wallet.walletName,
                              address: wallet.walletAddress,
                              isSelected: sellectedWallet == index,
                              padding: const EdgeInsets.all(16),
                              onTap: () {
                                setState(() {
                                  sellectedWallet = index;
                                });
                                walletTap(index);
                              },
                              icons: [
                                if (wallet.walletType == 0)
                                  'assets/icons/ledger.svg',
                                if (wallet.walletType == 1)
                                  'assets/icons/document.svg',
                                if (wallet.walletType == 2)
                                  'assets/icons/bincode.svg',
                                if (wallet.authType == "faceId")
                                  'assets/icons/face_id.svg',
                                if (wallet.authType == "fingerprint")
                                  'assets/icons/fingerprint.svg',
                                if (wallet.authType == "biometric")
                                  'assets/icons/biometric.svg',
                                if (wallet.authType == "pinCode")
                                  'assets/icons/pin.svg',
                              ],
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                child: Blockies(
                                  seed: wallet.walletAddress,
                                  color: _getWalletColor(index),
                                  bgColor: theme.primaryPurple,
                                  spotColor: theme.background,
                                  size: 8,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SmartInput(
                            key: _passwordInputKey,
                            controller: passwordController,
                            hint: "Password",
                            fontSize: 18,
                            height: 50,
                            disabled: sellectedWallet == -1 ||
                                _appState.wallets[sellectedWallet].walletType ==
                                    0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            focusedBorderColor: theme.primaryPurple,
                            obscureText: obscurePassword,
                            onFocusChanged: (isFocused) {
                              setState(() {
                                obscureButton = !isFocused;
                              });
                            },
                            rightIconPath: obscurePassword
                                ? "assets/icons/close_eye.svg"
                                : "assets/icons/open_eye.svg",
                            onRightIconTap: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          if (obscureButton)
                            SizedBox(
                              width: double.infinity,
                              child: RoundedLoadingButton(
                                controller: _btnController,
                                onPressed: unlock,
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
                                  'Unlock',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
