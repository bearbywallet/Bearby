import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/wallet_option.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/services/biometric_service.dart';
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
  final AuthService _authService = AuthService();

  late AppState _appState;

  bool obscurePassword = true;
  bool obscureButton = true;
  int sellectedWallet = -1;

  @override
  void initState() {
    super.initState();

    _appState = Provider.of<AppState>(context, listen: false);
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
      if (wallet.walletType == 0) {
        toHome();
        return;
      }

      if (wallet.authType != "none") {
        final authenticated = await _authService.authenticate(
          allowPinCode: true,
          reason: 'Please authenticate',
        );

        if (!authenticated) {
          return;
        }

        // TODO: add session check

        toHome();
      }
    } catch (e) {
      print("try unlock with biometric $e");
    }
  }

  Future<void> unlock() async {
    final wallet = _appState.wallets[sellectedWallet];

    try {
      // if Ledger device
      if (wallet.walletType == 0) {
        toHome();
        return;
      }

      if (passwordController.text.isNotEmpty) {
        // TODO: add password check.
        return;
      }

      if (wallet.authType != "none") {
        final authenticated = await _authService.authenticate(
          allowPinCode: true,
          reason: 'Please authenticate',
        );

        if (!authenticated) {
          return;
        }

        toHome();
      }
    } catch (e) {
      print("try unlock with biometric $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    final screenSize = MediaQuery.of(context).size;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final adaptivePaddingWalletOption =
        AdaptiveSize.getAdaptivePadding(context, 16);

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
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/new_wallet_options');
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/plus.svg',
                        width: 32,
                        height: 32,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: Column(
                      children: [
                        const Spacer(),
                        Center(
                          child: Text(
                            'Welcome back',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _appState.wallets.length,
                            itemBuilder: (context, index) {
                              final wallet = _appState.wallets[index];

                              if (!obscureButton && sellectedWallet != index) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding:
                                    EdgeInsets.only(top: index > 0 ? 4 : 0),
                                child: WalletOption(
                                  title: wallet.walletName.isEmpty
                                      ? "Wallet ${index + 1}"
                                      : wallet.walletName,
                                  address: wallet.walletAddress,
                                  isSelected: sellectedWallet == index,
                                  padding: EdgeInsets.all(
                                      adaptivePaddingWalletOption),
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
                                      )),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SmartInput(
                          key: _passwordInputKey,
                          controller: passwordController,
                          hint: "Password",
                          fontSize: 18,
                          height: 50,
                          disabled: sellectedWallet == -1,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: theme.primaryPurple,
                          obscureText: obscurePassword,
                          onFocusChanged: (isFocused) {
                            obscureButton = !isFocused;
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
                          CustomButton(
                            text: 'Confirm',
                            onPressed: unlock,
                            backgroundColor: theme.primaryPurple,
                            borderRadius: 30.0,
                            height: 50.0,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
