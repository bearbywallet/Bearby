import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/state/app_state.dart' as app_state;
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, bool> _hoverStates = {};

  void _updateHoverState(String key, bool isHovered) {
    setState(() {
      _hoverStates[key] = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final appState = Provider.of<app_state.AppState>(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Settings',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      children: [
                        _buildWalletSection(theme, appState),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            title: 'Language',
                            svgPath: 'assets/icons/language.svg',
                            trailingSvgPath: 'assets/icons/abc.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Currency',
                            svgPath: 'assets/icons/currency.svg',
                            trailingSvgPath: 'assets/icons/exchange.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Theme',
                            svgPath: 'assets/icons/theme.svg',
                            trailingSvgPath: 'assets/icons/color.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Notifications',
                            svgPath: 'assets/icons/notification.svg',
                            trailingSvgPath: 'assets/icons/bell.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Address book',
                            svgPath: 'assets/icons/book.svg',
                            trailingSvgPath: 'assets/icons/menu-book.svg',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            title: 'Security & privacy',
                            svgPath: 'assets/icons/security.svg',
                            trailingSvgPath: 'assets/icons/shield.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Networks',
                            svgPath: 'assets/icons/network.svg',
                            trailingSvgPath: 'assets/icons/globe.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Alerts',
                            svgPath: 'assets/icons/alert.svg',
                            trailingSvgPath: 'assets/icons/warning.svg',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(theme, [
                          SettingsItem(
                            title: 'Telegram',
                            svgPath: 'assets/icons/telegram.svg',
                            trailingSvgPath: 'assets/icons/send.svg',
                            onTap: () => _launchURL('https://t.me/zilpaychat'),
                          ),
                          SettingsItem(
                            title: 'Twitter',
                            svgPath: 'assets/icons/twitter.svg',
                            trailingSvgPath: 'assets/icons/x.svg',
                            onTap: () =>
                                _launchURL('https://twitter.com/zilpay'),
                          ),
                          SettingsItem(
                            title: 'About',
                            svgPath: 'assets/icons/info.svg',
                            trailingSvgPath: 'assets/icons/info-circle.svg',
                            onTap: () {},
                          ),
                          SettingsItem(
                            title: 'Contact us',
                            svgPath: 'assets/icons/contact.svg',
                            trailingSvgPath: 'assets/icons/arrow-right.svg',
                            onTap: () {},
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSection(AppTheme theme, app_state.AppState appState) {
    return MouseRegion(
      onEnter: (_) => _updateHoverState('wallet', true),
      onExit: (_) => _updateHoverState('wallet', false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/wallet'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hoverStates['wallet'] ?? false
                ? theme.cardBackground.withOpacity(0.7)
                : theme.cardBackground.withOpacity(0.6),
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
      ),
    );
  }

  Widget _buildSettingsGroup(AppTheme theme, List<SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) => _buildSettingsItem(theme, item)).toList(),
      ),
    );
  }

  Widget _buildSettingsItem(AppTheme theme, SettingsItem item) {
    return MouseRegion(
      onEnter: (_) => _updateHoverState(item.title, true),
      onExit: (_) => _updateHoverState(item.title, false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hoverStates[item.title] ?? false
                ? theme.primaryPurple.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                item.svgPath,
                colorFilter: ColorFilter.mode(
                  theme.textPrimary,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              SvgPicture.asset(
                item.trailingSvgPath,
                colorFilter: ColorFilter.mode(
                  theme.primaryPurple,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppTheme theme) {
    return MouseRegion(
      onEnter: (_) => _updateHoverState('logout', true),
      onExit: (_) => _updateHoverState('logout', false),
      child: GestureDetector(
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            // Handle logout logic here
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/initial', (route) => false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hoverStates['logout'] ?? false
                ? Colors.red.withOpacity(0.2)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/logout.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.red,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Log out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/door.svg',
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
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    // Implement your URL launcher logic here
    // Usually with url_launcher package
  }
}

class SettingsItem {
  final String title;
  final String svgPath;
  final String trailingSvgPath;
  final VoidCallback onTap;

  SettingsItem({
    required this.title,
    required this.svgPath,
    required this.trailingSvgPath,
    required this.onTap,
  });
}
