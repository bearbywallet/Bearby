import 'package:flutter/material.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/components/toggle_item.dart';
import '../theme/theme_provider.dart';

class CipherSettingsPage extends StatefulWidget {
  const CipherSettingsPage({
    super.key,
  });

  @override
  State<CipherSettingsPage> createState() => _CipherSettingsPageState();
}

class _CipherSettingsPageState extends State<CipherSettingsPage> {
  int selectedCipherIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Setup Cipher',
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
                        const SizedBox(height: 16),
                        OptionsList(
                          options: [
                            OptionItem(
                              title: 'Basic encryption',
                              isSelected: selectedCipherIndex == 0,
                              onSelect: () =>
                                  setState(() => selectedCipherIndex = 0),
                            ),
                            OptionItem(
                              title: 'Advanced encryption (Recommended)',
                              isSelected: selectedCipherIndex == 1,
                              onSelect: () =>
                                  setState(() => selectedCipherIndex = 1),
                            ),
                            OptionItem(
                              title: 'Hardware encryption',
                              isSelected: selectedCipherIndex == 2,
                              onSelect: () =>
                                  setState(() => selectedCipherIndex = 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selected encryption method provides secure storage for your wallet data.',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomButton(
                  text: 'Next',
                  onPressed: () {},
                  backgroundColor: theme.primaryPurple,
                  borderRadius: 30.0,
                  height: 56.0,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
