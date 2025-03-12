import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/switch_setting_item.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  int selectedThemeIndex = 0;
  bool compactNumbers = false;

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: l10n.appearanceSettingsPageTitle,
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
                            backgroundColor: theme.cardBackground,
                            iconPath: "assets/icons/pin.svg",
                            title:
                                l10n.appearanceSettingsPageCompactNumbersTitle,
                            description: l10n
                                .appearanceSettingsPageCompactNumbersDescription,
                            value: compactNumbers,
                            onChanged: _handleCompactNumbersChange,
                          ),
                          const SizedBox(height: 24),
                          OptionsList(
                            options: [
                              OptionItem(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.appearanceSettingsPageDeviceSettingsTitle,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.appearanceSettingsPageDeviceSettingsSubtitle,
                                      style: TextStyle(
                                        color: theme.primaryPurple,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.appearanceSettingsPageDeviceSettingsDescription,
                                      style: TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                isSelected: selectedThemeIndex == 0,
                                onSelect: () => _handleThemeSelection(0),
                              ),
                              OptionItem(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.appearanceSettingsPageDarkModeTitle,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.appearanceSettingsPageDarkModeSubtitle,
                                      style: TextStyle(
                                        color: theme.primaryPurple,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.appearanceSettingsPageDarkModeDescription,
                                      style: TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                isSelected: selectedThemeIndex == 1,
                                onSelect: () => _handleThemeSelection(1),
                              ),
                              OptionItem(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.appearanceSettingsPageLightModeTitle,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.appearanceSettingsPageLightModeSubtitle,
                                      style: TextStyle(
                                        color: theme.primaryPurple,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.appearanceSettingsPageLightModeDescription,
                                      style: TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                isSelected: selectedThemeIndex == 2,
                                onSelect: () => _handleThemeSelection(2),
                              ),
                            ],
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
