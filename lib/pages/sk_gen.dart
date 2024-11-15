import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/hex_key.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import '../theme/theme_provider.dart';
import '../components/gradient_bg.dart';

class SecretKeyGeneratorPage extends StatefulWidget {
  const SecretKeyGeneratorPage({
    super.key,
  });

  @override
  State<SecretKeyGeneratorPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<SecretKeyGeneratorPage> {
  KeyPair _keyPair = KeyPair(sk: "", pk: "");

  @override
  void initState() {
    super.initState();
    _regenerateKeys();
  }

  Future<void> _regenerateKeys() async {
    KeyPair keyPair = await genKeypair();

    setState(() {
      _keyPair = keyPair;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  CustomAppBar(
                    title: 'Secret Key',
                    onBackPressed: () => Navigator.pop(context),
                    actionIconPath: 'assets/icons/reload.svg',
                    onActionPressed: _regenerateKeys,
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HexKeyDisplay(
                            hexKey: _keyPair.sk,
                            title: "Private Key",
                          ),
                          const SizedBox(height: 16),
                          HexKeyDisplay(
                            hexKey: _keyPair.sk,
                            title: "Publick Key",
                          ),
                        ],
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
}
