import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/wallet_option.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/theme/theme_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final screenSize = MediaQuery.of(context).size;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final passwordController = TextEditingController();
    // final passwordInputKey = GlobalKey<SmartInputState>();

    bool obscurePassword = true;

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Positioned(
            child: SizedBox(
              height: screenSize.height * 0.6,
              child: Transform.scale(
                scale: 1.2,
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
            child: Padding(
              padding: EdgeInsets.all(adaptivePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WalletOption(
                    title: 'Main account',
                    address: 'pil3f...sts157',
                    isSelected: true,
                    onTap: () {},
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF55A2F2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  WalletOption(
                    title: 'Hidden account',
                    address: 'uvw9k...ghi678',
                    isSelected: false,
                    onTap: () {},
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB347),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  WalletOption(
                    title: 'Waork account',
                    address: 'mno7y...qrs843',
                    isSelected: false,
                    onTap: () {},
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ECFB0),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SmartInput(
                    // key: passwordInputKey,
                    controller: passwordController,
                    hint: "Password",
                    fontSize: 18,
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    focusedBorderColor: theme.primaryPurple,
                    obscureText: obscurePassword,
                    rightIconPath: obscurePassword
                        ? "assets/icons/close_eye.svg"
                        : "assets/icons/open_eye.svg",
                    // onChanged: (value) {},
                    onRightIconTap: () {
                      // setState(() {
                      //   obscurePassword = !obscurePassword;
                      // });
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Confirm',
                    onPressed: () {},
                    backgroundColor: theme.primaryPurple,
                    borderRadius: 30.0,
                    height: 50.0,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
