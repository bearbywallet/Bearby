import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/switch_setting_item.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  int selectedThemeIndex = 0;
  bool compactNumbers = false;

  final List<Map<String, String>> themeDescriptions = [
    {
      'title': 'Device settings',
      'subtitle': 'System default',
      'description':
          "Default to your device's appearance. Your wallet theme will automatically adjust based on your system settings.",
    },
    {
      'title': 'Dark Mode',
      'subtitle': 'Always dark',
      'description':
          'Keep the dark theme enabled at all times, regardless of your device settings.',
    },
    {
      'title': 'Light mode',
      'subtitle': 'Always light',
      'description':
          'Keep the light theme enabled at all times, regardless of your device settings.',
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<AppState>(context, listen: false);
    setState(() {
      selectedThemeIndex = themeProvider.state.appearances;
      compactNumbers = themeProvider.state.abbreviatedNumber;
    });
  }

  Future<void> _handleThemeSelection(int index) async {
    final stateProvider = Provider.of<AppState>(context, listen: false);
    await stateProvider.setAppearancesCode(index, compactNumbers);
    setState(() {
      selectedThemeIndex = index;
    });
    await stateProvider.syncData();
  }

  Future<void> _handleCompactNumbersChange(bool value) async {
    final stateProvider = Provider.of<AppState>(context, listen: false);
    await stateProvider.setAppearancesCode(selectedThemeIndex, value);
    setState(() {
      compactNumbers = value;
    });
    await stateProvider.syncData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Appearance Settings',
                  onBackPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchSettingItem(
                            title: 'Compact Numbers',
                            description:
                                'Enable to display abbreviated numbers (e.g., 20K instead of 20,000).',
                            value: compactNumbers,
                            onChanged: _handleCompactNumbersChange,
                          ),
                          const SizedBox(height: 24),
                          OptionsList(
                            options: List.generate(
                              themeDescriptions.length,
                              (index) => OptionItem(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      themeDescriptions[index]['title']!,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      themeDescriptions[index]['subtitle']!,
                                      style: TextStyle(
                                        color: theme.primaryPurple,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      themeDescriptions[index]['description']!,
                                      style: TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                isSelected: selectedThemeIndex == index,
                                onSelect: () => _handleThemeSelection(index),
                              ),
                            ),
                            unselectedOpacity: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
