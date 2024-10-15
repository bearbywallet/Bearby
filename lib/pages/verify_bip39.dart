import 'package:flutter/material.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import '../theme/theme_provider.dart';

class SecretPhraseVerifyPage extends StatefulWidget {
  const SecretPhraseVerifyPage({
    super.key,
  });

  @override
  State<SecretPhraseVerifyPage> createState() => _VerifyBip39PageState();
}

class _VerifyBip39PageState extends State<SecretPhraseVerifyPage> {
  List<String>? _bip39_list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, List<String>>?;

    if (args == null || args['bip39'] == null || args['bip39']!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39_list = args['bip39'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Verify Secret',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: _bip39_list == null
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Bip39 Secret',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textPrimary,
                              ),
                            ),
                          ],
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
