import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/wallet_option.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
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

  bool obscurePassword = true;
  bool obscureButton = true;
  int sellectedWallet = 0;

  Color _getWalletColor(int index) {
    final colors = [
      const Color(0xFF55A2F2),
      const Color(0xFFFFB347),
      const Color(0xFF4ECFB0),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final appState = Provider.of<AppState>(context);

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
              mainAxisAlignment: MainAxisAlignment.end,
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
                        SizedBox(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...appState.wallets
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final wallet = entry.value;

                                  return Column(
                                    children: [
                                      if (index > 0) const SizedBox(height: 4),
                                      WalletOption(
                                        title: "Wallet ${index + 1}",
                                        address: wallet.walletAddress,
                                        isSelected: sellectedWallet == index,
                                        padding: EdgeInsets.all(
                                            adaptivePaddingWalletOption),
                                        onTap: () {
                                          sellectedWallet = index;
                                        },
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _getWalletColor(index),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SmartInput(
                          key: _passwordInputKey,
                          controller: passwordController,
                          hint: "Password",
                          fontSize: 18,
                          height: 50,
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
                            onPressed: () {},
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
