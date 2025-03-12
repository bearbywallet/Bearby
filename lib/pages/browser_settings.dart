import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button_item.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/switch_setting_item.dart';
import 'package:zilpay/config/search_engines.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/list_selector.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class BrowserSettingsPage extends StatefulWidget {
  const BrowserSettingsPage({super.key});

  @override
  State<BrowserSettingsPage> createState() => _BrowserSettingsPageState();
}

class _BrowserSettingsPageState extends State<BrowserSettingsPage> {
  final List<ListItem> searchEngines = baseSearchEngines
      .map((s) => ListItem(title: s.name, subtitle: s.description))
      .toList();

  final List<ListItem> contentBlockingOptions = [
    ListItem(title: 'Off', subtitle: 'No content blocking'),
    ListItem(title: 'Moderate', subtitle: 'Blocks some trackers and ads'),
    ListItem(title: 'Strict', subtitle: 'Blocks most trackers and ads'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _toggleCache(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(cacheEnabled: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling cache: $e");
    }
  }

  Future<void> _toggleCookies(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(cookiesEnabled: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling cookies: $e");
    }
  }

  Future<void> _toggleDoNotTrack(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(doNotTrack: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling do not track: $e");
    }
  }

  Future<void> _toggleIncognitoMode(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(incognitoMode: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling incognito mode: $e");
    }
  }

  void _showSearchEngineModal(AppState appState) {
    showListSelectorModal(
      context: context,
      title: AppLocalizations.of(context)!.browserSettingsSearchEngineTitle,
      items: searchEngines,
      selectedIndex: appState.state.browserSettings.searchEngineIndex,
      onItemSelected: (index) async {
        final appState = Provider.of<AppState>(context, listen: false);
        try {
          BrowserSettingsInfo newSettings =
              appState.state.browserSettings.copyWith(searchEngineIndex: index);
          await setBrowserSettings(browserSettings: newSettings);
          await appState.syncData();
        } catch (e) {
          debugPrint("Error setting search engine: $e");
        }
      },
    );
  }

  void _showContentBlockingModal(AppState appState) {
    showListSelectorModal(
      context: context,
      title: AppLocalizations.of(context)!.browserSettingsContentBlockingTitle,
      items: contentBlockingOptions,
      selectedIndex: appState.state.browserSettings.contentBlocking,
      onItemSelected: (index) async {
        final appState = Provider.of<AppState>(context, listen: false);
        try {
          BrowserSettingsInfo newSettings =
              appState.state.browserSettings.copyWith(contentBlocking: index);
          await setBrowserSettings(browserSettings: newSettings);
          await appState.syncData();
        } catch (e) {
          debugPrint("Error setting content blocking: $e");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: AppLocalizations.of(context)!.browserSettingsTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
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
                          _buildButtonSection(theme, appState),
                          const SizedBox(height: 24),
                          _buildPrivacySection(theme, appState),
                          const SizedBox(height: 24),
                          _buildPerformanceSection(theme, appState),
                          const SizedBox(height: 24),
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

  Widget _buildButtonSection(AppTheme theme, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            AppLocalizations.of(context)!.browserSettingsBrowserOptions,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ButtonItem(
                theme: theme,
                title:
                    AppLocalizations.of(context)!.browserSettingsSearchEngine,
                iconPath: 'assets/icons/search.svg',
                description: AppLocalizations.of(context)!
                    .browserSettingsSearchEngineDescription,
                onTap: () => _showSearchEngineModal(appState),
                subtitleText: searchEngines[
                        appState.state.browserSettings.searchEngineIndex]
                    .title,
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              ButtonItem(
                theme: theme,
                title: AppLocalizations.of(context)!
                    .browserSettingsContentBlocking,
                iconPath: 'assets/icons/shield.svg',
                description: AppLocalizations.of(context)!
                    .browserSettingsContentBlockingDescription,
                onTap: () => _showContentBlockingModal(appState),
                subtitleText: contentBlockingOptions[
                        appState.state.browserSettings.contentBlocking]
                    .title,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(AppTheme theme, AppState appState) {
    final settings = appState.state.browserSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            AppLocalizations.of(context)!.browserSettingsPrivacySecurity,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchSettingItem(
                title: AppLocalizations.of(context)!.browserSettingsCookies,
                iconPath: 'assets/icons/cookie.svg',
                description: AppLocalizations.of(context)!
                    .browserSettingsCookiesDescription,
                value: settings.cookiesEnabled,
                onChanged: (value) => _toggleCookies(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              SwitchSettingItem(
                title: AppLocalizations.of(context)!.browserSettingsDoNotTrack,
                iconPath: 'assets/icons/shield.svg',
                description: AppLocalizations.of(context)!
                    .browserSettingsDoNotTrackDescription,
                value: settings.doNotTrack,
                onChanged: (value) => _toggleDoNotTrack(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              SwitchSettingItem(
                title:
                    AppLocalizations.of(context)!.browserSettingsIncognitoMode,
                iconPath: 'assets/icons/incognito.svg',
                description: AppLocalizations.of(context)!
                    .browserSettingsIncognitoModeDescription,
                value: settings.incognitoMode,
                onChanged: (value) => _toggleIncognitoMode(appState, value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(AppTheme theme, AppState appState) {
    final settings = appState.state.browserSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            AppLocalizations.of(context)!.browserSettingsPerformance,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchSettingItem(
                title: AppLocalizations.of(context)!.browserSettingsCache,
                iconPath: 'assets/icons/cache.svg',
                description: AppLocalizations.of(context)!
                    .browserSettingsCacheDescription,
                value: settings.cacheEnabled,
                onChanged: (value) => _toggleCache(appState, value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
