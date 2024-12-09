import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/settings_item.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/services/social_media.dart';
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
    final SocialMediaService socialMediaService = SocialMediaService();
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
                            title: 'Language',
                            trailingSvgPath: 'assets/icons/language.svg',
                            onTap: () =>
                                {Navigator.pushNamed(context, '/language')},
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            isFirst: true,
                            isLast: false,
                            title: 'Telegram',
                            trailingSvgPath: 'assets/icons/telegram.svg',
                            onTap: () => socialMediaService.openTelegram(
                                username: 'zilpaychat'),
                          ),
                          SettingsItem(
                            title: 'Twitter',
                            trailingSvgPath: 'assets/icons/x.svg',
                            onTap: () =>
                                socialMediaService.openX(username: 'pay_zil'),
                          ),
                          SettingsItem(
                            isFirst: false,
                            isLast: true,
                            title: 'About',
                            trailingSvgPath: 'assets/icons/info.svg',
                            onTap: () => Navigator.pushNamed(context, '/about'),
                          ),
                        ]),
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
                  appState.wallet!.walletName,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Ethereum (ETH)', // TODO: add Netowrk name!
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
}
