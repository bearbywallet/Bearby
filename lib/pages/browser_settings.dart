import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/button_item.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/switch_setting_item.dart';
import 'package:zilpay/config/search_engines.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
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

class _BrowserSettingsPageState extends State<BrowserSettingsPage>
    with StatusBarMixin {
  final List<ListItem> searchEngines = baseSearchEngines
      .map((s) => ListItem(title: s.name, subtitle: s.description))
      .toList();

  final List<ListItem> contentBlockingOptions = [
    ListItem(title: 'Off', subtitle: 'No content blocking'),
    ListItem(title: 'Moderate', subtitle: 'Blocks some trackers and ads'),
    ListItem(title: 'Strict', subtitle: 'Blocks most trackers and ads'),
  ];

  // Track which clear operations are currently loading
  final Set<String> _loading = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Helper method to set loading state
  void _setLoading(String operation, bool isLoading) {
    setState(() {
      if (isLoading) {
        _loading.add(operation);
      } else {
        _loading.remove(operation);
      }
    });
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

  Future<void> _clearCookies(AppState appState) async {
    final String operation = 'cookies';
    try {
      _setLoading(operation, true);
      await CookieManager.instance().deleteAllCookies();
      await CookieManager.instance().removeSessionCookies();
      await appState.syncData();
    } catch (e) {
      debugPrint("Error clearing cookies: $e");
    } finally {
      _setLoading(operation, false);
    }
  }

  Future<void> _clearCache(AppState appState) async {
    final String operation = 'cache';
    try {
      _setLoading(operation, true);
      await InAppWebViewController.clearAllCache();
      await appState.syncData();
    } catch (e) {
      debugPrint("Error clearing cache: $e");
    } finally {
      _setLoading(operation, false);
    }
  }

  Future<void> _clearLocalStorage(AppState appState) async {
    final String operation = 'localStorage';
    try {
      _setLoading(operation, true);
      final headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("about:blank")),
        onLoadStop: (controller, url) async {
          try {
            await controller.evaluateJavascript(
                source: "localStorage.clear();");
            await controller.evaluateJavascript(
                source: "sessionStorage.clear();");
            await controller.evaluateJavascript(source: """
            if (window.indexedDB) {
              window.indexedDB.deleteDatabase('all');
            }
          """);

            await controller.clearHistory();
          } catch (e) {
            debugPrint("Error in JavaScript execution: $e");
          }
        },
      );

      await headlessWebView.run();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await appState.syncData();
    } catch (e) {
      debugPrint("Error clearing localStorage: $e");
    } finally {
      _setLoading(operation, false);
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
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
                          _buildClearDataSection(theme, appState),
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
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
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
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
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
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
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

  Widget _buildClearDataSection(AppTheme theme, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            AppLocalizations.of(context)!.browserSettingsClearData,
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
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
              _buildClearDataItem(
                theme,
                AppLocalizations.of(context)!.browserSettingsClearCookies,
                'assets/icons/cookie.svg',
                AppLocalizations.of(context)!
                    .browserSettingsClearCookiesDescription,
                () => _clearCookies(appState),
                _loading.contains('cookies'),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildClearDataItem(
                theme,
                AppLocalizations.of(context)!.browserSettingsClearCache,
                'assets/icons/cache.svg',
                AppLocalizations.of(context)!
                    .browserSettingsClearCacheDescription,
                () => _clearCache(appState),
                _loading.contains('cache'),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildClearDataItem(
                theme,
                AppLocalizations.of(context)!.browserSettingsClearLocalStorage,
                'assets/icons/data.svg',
                AppLocalizations.of(context)!
                    .browserSettingsClearLocalStorageDescription,
                () => _clearLocalStorage(appState),
                _loading.contains('localStorage'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClearDataItem(
    AppTheme theme,
    String title,
    String iconPath,
    String description,
    VoidCallback onTap,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              theme.textPrimary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodyLarge.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.bodyText2.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isLoading ? null : onTap,
            style: TextButton.styleFrom(
              foregroundColor: theme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primaryPurple),
                    ),
                  )
                : Text(AppLocalizations.of(context)!.browserSettingsClear),
          ),
        ],
      ),
    );
  }
}
