import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/option_list.dart';
import '../theme/theme_provider.dart';

class CipherSettingsPage extends StatefulWidget {
  const CipherSettingsPage({
    super.key,
  });

  @override
  State<CipherSettingsPage> createState() => _CipherSettingsPageState();
}

class _CipherSettingsPageState extends State<CipherSettingsPage> {
  final _btnController = RoundedLoadingButtonController();
  int selectedCipherIndex = 2;

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
                title: 'Setup Encryption',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose encryption method',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select the level of encryption for your wallet security',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OptionsList(
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (selectedCipherIndex == 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Post-quantum encryption might affect performance',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    RoundedLoadingButton(
                      controller: _btnController,
                      onPressed: () async {
                        _btnController.start();
                        try {
                          Timer(const Duration(seconds: 5), () {
                            _btnController.success();
                          });
                        } catch (e) {
                          _btnController.error();
                        }
                      },
                      successIcon: SvgPicture.asset(
                        'assets/icons/ok.svg',
                        width: 24,
                        height: 24,
                        colorFilter:
                            ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    // CustomButton(
                    //   text: 'Confirm',
                    //   onPressed: () {
                    //     // Navigator.pushNamed(context, '/next_route');
                    //   },
                    //   backgroundColor: theme.primaryPurple,
                    //   borderRadius: 30.0,
                    //   height: 56.0,
                    // ),
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
