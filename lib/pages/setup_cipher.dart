import 'package:flutter/material.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import '../theme/theme_provider.dart';

class CipherSettingsPage extends StatefulWidget {
  const CipherSettingsPage({
    super.key,
  });

  @override
  State<CipherSettingsPage> createState() => _CipherSettingsPageState();
}

class _CipherSettingsPageState extends State<CipherSettingsPage> {
  List<String>? _bip39List;
  List<int>? _codes;
  final _btnController = RoundedLoadingButtonController();
  int selectedCipherIndex = 2;
  bool optionsDisabled = false;

  final List<Map<String, String>> cipherDescriptions = [
    {
      'title': 'Standard Encryption',
      'subtitle': 'AES-256',
      'description':
          'Basic level encryption suitable for most users. Uses AES-256 algorithm - current industry standard.',
    },
    {
      'title': 'Enhanced Security',
      'subtitle': 'AES-256 + TwoFish',
      'description':
          'Recommended. Double layer encryption using AES-256 and TwoFish for enhanced security.',
    },
    {
      'title': 'Post-Quantum Protection',
      'subtitle': 'AES-256 + NTRU-Prime',
      'description':
          'Highest security level with quantum resistance. Combines AES-256 with NTRU-Prime algorithm.',
    },
  ];

  @override
  void reassemble() {
    super.reassemble();
    _btnController.reset();

    setState(() {
      optionsDisabled = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final codes = args?['codes'] as List<int>?;

    if (bip39 == null || codes == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/gen_bip39');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _codes = codes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Setup Encryption',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OptionsList(
                          disabled: optionsDisabled,
                          options: List.generate(
                            cipherDescriptions.length,
                            (index) => OptionItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cipherDescriptions[index]['title']!,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cipherDescriptions[index]['subtitle']!,
                                    style: TextStyle(
                                      color: theme.primaryPurple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cipherDescriptions[index]['description']!,
                                    style: TextStyle(
                                      color: theme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              isSelected: selectedCipherIndex == index,
                              onSelect: () =>
                                  setState(() => selectedCipherIndex = index),
                            ),
                          ),
                          unselectedOpacity: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(adaptivePadding),
                child: Column(
                  children: [
                    if (selectedCipherIndex == 2)
                      Padding(
                        padding: EdgeInsets.only(bottom: adaptivePadding),
                        child: Text(
                          'Post-quantum encryption might affect performance',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    CustomButton(
                      text: 'Confirm',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/pass_setup',
                            arguments: {
                              'bip39': _bip39List,
                              'codes': _codes,
                              'cipher': selectedCipherIndex
                            });
                      },
                      backgroundColor: theme.primaryPurple,
                      borderRadius: 30.0,
                      height: 56.0,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
