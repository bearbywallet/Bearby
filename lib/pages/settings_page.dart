import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/settings_item.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/state/app_state.dart' as app_state;
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final appState = Provider.of<app_state.AppState>(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Settings',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  physics: const BouncingScrollPhysics(),
                  overscroll: true,
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      children: [
                        _buildWalletSection(theme, appState),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            isFirst: true,
                            isLast: false,
                            title: 'Language',
                            trailingSvgPath: 'assets/icons/language.svg',
                            onTap: () {
                              debugPrint("dasdsadsa");
                            },
                          ),
                          SettingsItem(
                            title: 'Currency',
                            trailingSvgPath: 'assets/icons/currency.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/currency'),
                          ),
                          SettingsItem(
                            title: 'Appearance',
                            trailingSvgPath: 'assets/icons/appearance.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/appearance'),
                          ),
                          SettingsItem(
                            title: 'Notifications',
                            trailingSvgPath: 'assets/icons/bell.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/notifications'),
                          ),
                          SettingsItem(
                            isFirst: false,
                            isLast: true,
                            title: 'Address book',
                            trailingSvgPath: 'assets/icons/book.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/address-book'),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            isFirst: true,
                            isLast: false,
                            title: 'Security & privacy',
                            trailingSvgPath: 'assets/icons/shield.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/security'),
                          ),
                          SettingsItem(
                            title: 'Networks',
                            trailingSvgPath: 'assets/icons/globe.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/networks'),
                          ),
                          SettingsItem(
                            isFirst: false,
                            isLast: true,
                            title: 'Alerts',
                            trailingSvgPath: 'assets/icons/warning.svg',
                            onTap: () =>
                                Navigator.pushNamed(context, '/alerts'),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            isFirst: true,
                            isLast: false,
                            title: 'Telegram',
                            trailingSvgPath: 'assets/icons/telegram.svg',
                            onTap: () => _launchURL('https://t.me/zilpaychat'),
                          ),
                          SettingsItem(
                            title: 'Twitter',
                            trailingSvgPath: 'assets/icons/x.svg',
                            onTap: () =>
                                _launchURL('https://twitter.com/zilpay'),
                          ),
                          SettingsItem(
                            isFirst: false,
                            isLast: true,
                            title: 'About',
                            trailingSvgPath: 'assets/icons/info.svg',
                            onTap: () => Navigator.pushNamed(context, '/about'),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildLogoutButton(theme),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(AppTheme theme, app_state.AppState appState) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/wallet'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Blockies(
                  seed: appState.account!.addr,
                  color: getWalletColor(0),
                  bgColor: theme.primaryPurple,
                  spotColor: theme.background,
                  size: 8,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main wallet',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Ethereum (ETH)',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(AppTheme theme, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              item,
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: theme.textSecondary.withOpacity(0.1),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogoutButton(AppTheme theme) {
    return GestureDetector(
      onTap: () async {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Delete Wallet',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/logout.svg',
              colorFilter: const ColorFilter.mode(
                Colors.red,
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    // Implement your URL launcher logic here
    // Use url_launcher package
  }
}
