import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/theme/theme_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: screenSize.height * 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
