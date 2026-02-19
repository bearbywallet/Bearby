import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import '../state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

const String kTestnetEnabledKey = 'testnet_enabled';
const int kTapsToEnableTestnet = 7;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with StatusBarMixin {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Bearby',
    packageName: '',
    version: '',
    buildNumber: '',
  );
  int _logoTapCount = 0;
  bool _testnetEnabled = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _loadTestnetPreference();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _loadTestnetPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kTestnetEnabledKey) ?? false;
    if (mounted) {
      setState(() {
        _testnetEnabled = enabled;
      });
    }
  }

  Future<void> _onLogoTap() async {
    _logoTapCount++;
    if (_logoTapCount >= kTapsToEnableTestnet) {
      _logoTapCount = 0;
      final prefs = await SharedPreferences.getInstance();
      final newValue = !_testnetEnabled;
      await prefs.setBool(kTestnetEnabledKey, newValue);
      if (mounted) {
        setState(() {
          _testnetEnabled = newValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue ? 'Testnet options enabled' : 'Testnet options disabled',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
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
                    title: l10n.aboutPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Column(
                        children: [
                          _buildLogoSection(theme, l10n),
                          SizedBox(height: adaptivePadding * 2),
                          _buildAppInfoSection(theme, l10n),
                          SizedBox(height: adaptivePadding * 1.5),
                          _buildDeveloperSection(theme, l10n),
                          SizedBox(height: adaptivePadding * 1.5),
                          _buildLegalSection(theme, l10n),
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

  Widget _buildLogoSection(AppTheme theme, AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: _onLogoTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/imgs/logo.svg',
                width: 80,
                height: 80,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.aboutPageAppName,
          style: theme.headline1.copyWith(
            color: theme.textPrimary,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aboutPageAppDescription,
          style: theme.bodyLarge.copyWith(
            color: theme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(AppTheme theme, AppLocalizations l10n) {
    return _buildSectionContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, l10n.aboutPageAppInfoTitle),
          const SizedBox(height: 16),
          _buildInfoRow(
            theme,
            l10n.aboutPageVersionLabel,
            '${_packageInfo.version} (${_packageInfo.buildNumber})',
          ),
          _buildInfoRow(
            theme,
            l10n.aboutPageBuildDateLabel,
            l10n.aboutPageBuildDateValue,
          ),
          _buildInfoRow(
            theme,
            l10n.aboutPagePlatformLabel,
            Theme.of(context).platform.toString().split('.').last,
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(AppTheme theme, AppLocalizations l10n) {
    return _buildSectionContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, l10n.aboutPageDeveloperTitle),
          const SizedBox(height: 16),
          _buildInfoRow(
            theme,
            l10n.aboutPageAuthorLabel,
            l10n.aboutPageAuthorValue,
          ),
          _buildInfoRow(
            theme,
            l10n.aboutPageWebsiteLabel,
            l10n.aboutPageWebsiteValue,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(AppTheme theme, AppLocalizations l10n) {
    return _buildSectionContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, l10n.aboutPageLegalTitle),
          const SizedBox(height: 16),
          _buildActionRow(
            theme,
            l10n.aboutPagePrivacyPolicy,
            'assets/icons/shield.svg',
            false,
            () => _launchUrl('https://zilpay.io/policy'),
          ),
          _buildActionRow(
            theme,
            l10n.aboutPageTermsOfService,
            'assets/icons/document.svg',
            false,
            () => _launchUrl('https://zilpay.io/terms'),
          ),
          _buildActionRow(
            theme,
            l10n.aboutPageLicenses,
            'assets/icons/licenses.svg',
            true,
            () => _showLicensePage(context, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _showLicensePage(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    return showLicensePage(
      context: context,
      applicationName: _packageInfo.appName,
      applicationVersion: _packageInfo.version,
      applicationIcon: SvgPicture.asset(
        'assets/imgs/logo.svg',
        width: 48,
        height: 48,
      ),
      applicationLegalese: l10n.aboutPageLegalese,
    );
  }

  Widget _buildSectionContainer(AppTheme theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildSectionTitle(AppTheme theme, String title) {
    return Text(
      title,
      style: theme.titleSmall.copyWith(
        color: theme.textPrimary,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInfoRow(AppTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.bodyLarge.copyWith(
                color: theme.textSecondary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: theme.bodyLarge.copyWith(
                color: theme.textPrimary,
                overflow: TextOverflow.ellipsis,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    AppTheme theme,
    String title,
    String iconPath,
    bool last,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: last
                  ? Colors.transparent
                  : theme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
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
                style: theme.bodyLarge.copyWith(
                  color: theme.textPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/right_arrow.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                theme.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
