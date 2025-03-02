import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/config/search_engines.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/list_selector.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

extension BrowserSettingsInfoExtension on BrowserSettingsInfo {
  BrowserSettingsInfo copyWith({
    int? searchEngineIndex,
    bool? cacheEnabled,
    bool? cookiesEnabled,
    int? contentBlocking,
    bool? doNotTrack,
    bool? incognitoMode,
    double? textScalingFactor,
    bool? allowGeolocation,
    bool? allowCamera,
    bool? allowMicrophone,
    bool? allowAutoPlay,
  }) {
    return BrowserSettingsInfo(
      searchEngineIndex: searchEngineIndex ?? this.searchEngineIndex,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cookiesEnabled: cookiesEnabled ?? this.cookiesEnabled,
      contentBlocking: contentBlocking ?? this.contentBlocking,
      doNotTrack: doNotTrack ?? this.doNotTrack,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      textScalingFactor: textScalingFactor ?? this.textScalingFactor,
      allowGeolocation: allowGeolocation ?? this.allowGeolocation,
      allowCamera: allowCamera ?? this.allowCamera,
      allowMicrophone: allowMicrophone ?? this.allowMicrophone,
      allowAutoPlay: allowAutoPlay ?? this.allowAutoPlay,
    );
  }
}

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
    ListItem(
      title: 'Off',
      subtitle: 'No content blocking',
    ),
    ListItem(
      title: 'Moderate',
      subtitle: 'Blocks some trackers and ads',
    ),
    ListItem(
      title: 'Strict',
      subtitle: 'Blocks most trackers and ads',
    ),
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

  Future<void> _setTextScalingFactor(AppState appState, double factor) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(textScalingFactor: factor);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error setting text scaling factor: $e");
    }
  }

  Future<void> _toggleGeolocation(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(allowGeolocation: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling geolocation: $e");
    }
  }

  Future<void> _toggleCamera(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(allowCamera: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling camera: $e");
    }
  }

  Future<void> _toggleMicrophone(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(allowMicrophone: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling microphone: $e");
    }
  }

  Future<void> _toggleAutoPlay(AppState appState, bool enabled) async {
    try {
      BrowserSettingsInfo newSettings =
          appState.state.browserSettings.copyWith(allowAutoPlay: enabled);
      await setBrowserSettings(browserSettings: newSettings);
      await appState.syncData();
    } catch (e) {
      debugPrint("Error toggling autoplay: $e");
    }
  }

  void _showSearchEngineModal(AppState appState) {
    showListSelectorModal(
      context: context,
      title: 'Search Engine',
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
      title: 'Content Blocking',
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
                    title: 'Browser Settings',
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
                          _buildPermissionsSection(theme, appState),
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
            'Browser Options',
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
              _buildButtonItem(
                theme,
                'Search Engine',
                'assets/icons/search.svg',
                'Configure your default search engine',
                () => _showSearchEngineModal(appState),
                subtitleText: searchEngines[
                        appState.state.browserSettings.searchEngineIndex]
                    .title,
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildButtonItem(
                theme,
                'Content Blocking',
                'assets/icons/shield.svg',
                'Configure content blocking settings',
                () => _showContentBlockingModal(appState),
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
            'Privacy & Security',
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
              _buildPreferenceItem(
                theme,
                'Cookies',
                'assets/icons/cookie.svg',
                'Allow websites to save and read cookies',
                true,
                settings.cookiesEnabled,
                (value) => _toggleCookies(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                theme,
                'Do Not Track',
                'assets/icons/shield.svg',
                'Request websites not to track your browsing',
                true,
                settings.doNotTrack,
                (value) => _toggleDoNotTrack(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                theme,
                'Incognito Mode',
                'assets/icons/incognito.svg',
                'Browse without saving history or cookies',
                true,
                settings.incognitoMode,
                (value) => _toggleIncognitoMode(appState, value),
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
            'Performance',
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
              _buildPreferenceItem(
                theme,
                'Cache',
                'assets/icons/cache.svg',
                'Store website data for faster loading',
                true,
                settings.cacheEnabled,
                (value) => _toggleCache(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildSliderItem(
                theme,
                'Text scaling',
                'assets/icons/text.svg',
                'Adjust the size of text on websites',
                settings.textScalingFactor,
                (value) => _setTextScalingFactor(appState, value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection(AppTheme theme, AppState appState) {
    final settings = appState.state.browserSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            'Site Permissions',
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
              _buildPreferenceItem(
                theme,
                'Geolocation',
                'assets/icons/location.svg',
                'Allow websites to access your location',
                true,
                settings.allowGeolocation,
                (value) => _toggleGeolocation(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                theme,
                'Camera',
                'assets/icons/camera.svg',
                'Allow websites to access your camera',
                true,
                settings.allowCamera,
                (value) => _toggleCamera(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                theme,
                'Microphone',
                'assets/icons/microphone.svg',
                'Allow websites to access your microphone',
                true,
                settings.allowMicrophone,
                (value) => _toggleMicrophone(appState, value),
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                theme,
                'Autoplay',
                'assets/icons/play.svg',
                'Allow websites to automatically play media',
                true,
                settings.allowAutoPlay,
                (value) => _toggleAutoPlay(appState, value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonItem(
    AppTheme theme,
    String title,
    String iconPath,
    String description,
    VoidCallback onTap, {
    String? subtitleText,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitleText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            color: theme.primaryPurple,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  description,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
    AppTheme theme,
    String title,
    String iconPath,
    String description,
    bool hasSwitch,
    bool value,
    Function(bool)? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasSwitch)
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: theme.primaryPurple,
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                description,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderItem(
    AppTheme theme,
    String title,
    String iconPath,
    String description,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                description,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 12),
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.primaryPurple,
                inactiveTrackColor: theme.textSecondary.withValues(alpha: 0.2),
                thumbColor: theme.primaryPurple,
                overlayColor: theme.primaryPurple.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
