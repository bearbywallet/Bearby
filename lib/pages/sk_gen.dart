import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
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
  bool _hasBackupWords = false;

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
          child: Column(
            children: [
              CustomAppBar(
                title: 'Secret Key',
                onBackPressed: () => Navigator.pop(context),
                actionIconPath: 'assets/icons/reload.svg',
                onActionPressed: _regenerateKeys,
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HexKeyDisplay(
                            hexKey: _keyPair.sk,
                            title: "Private Key",
                          ),
                          const SizedBox(height: 8),
                          HexKeyDisplay(
                            hexKey: _keyPair.sk,
                            title: "Public Key",
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.background.withOpacity(0.5),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                'I have backup Keys',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              value: _hasBackupWords,
                              onChanged: (newValue) {
                                setState(() {
                                  _hasBackupWords = newValue!;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: theme.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Next',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/net_setup',
                                  arguments: {'keys': _keyPair});
                            },
                            backgroundColor: theme.primaryPurple,
                            borderRadius: 30.0,
                            height: 56.0,
                            disabled: !_hasBackupWords,
                          ),
                          SizedBox(height: adaptivePadding),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
