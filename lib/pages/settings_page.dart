import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/settings_item.dart';
import 'package:zilpay/components/wallet_section.dart';
import 'package:zilpay/config/web3_constants.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/services/social_media.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final SocialMediaService socialMediaService = SocialMediaService();
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final Color effectiveBgColor = Theme.of(context).scaffoldBackgroundColor;
    final Brightness backgroundBrightness =
        ThemeData.estimateBrightnessForColor(effectiveBgColor);
    final Brightness statusBarIconBrightness =
        backgroundBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
    final Brightness statusBarBrightness = backgroundBrightness;

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
    );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: overlayStyle,
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
                    title: AppLocalizations.of(context)!.settingsPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        child: Column(
                          children: [
                            HoverableWalletSection(
                                theme: theme, appState: appState),
                            const SizedBox(height: 24),
                            _buildSettingsGroup(theme, [
                              if (appState.chain?.slip44 == kZilliqaSlip44 &&
                                  appState.wallet != null &&
                                  !appState.wallet!.walletType
                                      .contains(WalletType.ledger.name))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/scilla.svg',
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          theme.textPrimary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .settingsPageZilliqaLegacy,
                                          style: theme.bodyLarge.copyWith(
                                            color: theme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        padding: EdgeInsets.all(0),
                                        value: appState.account?.addrType ==
                                            kScillaAddressType,
                                        onChanged: (bool value) async {
                                          BigInt walletIndex = BigInt.from(
                                              appState.selectedWallet);
                                          await zilliqaSwapChain(
                                            walletIndex: walletIndex,
                                            accountIndex: appState
                                                .wallet!.selectedAccount,
                                          );
                                          await appState.syncData();

                                          try {
                                            await syncBalances(
                                              walletIndex: walletIndex,
                                            );
                                            await appState.syncData();
                                          } catch (_) {}
                                        },
                                        activeThumbColor: theme.primaryPurple,
                                        activeTrackColor: theme.primaryPurple
                                            .withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageCurrency,
                                trailingSvgPath: 'assets/icons/currency.svg',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/currency'),
                              ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageAppearance,
                                trailingSvgPath: 'assets/icons/appearance.svg',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/appearance'),
                              ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageNotifications,
                                trailingSvgPath: 'assets/icons/bell.svg',
                                onTap: () => Navigator.pushNamed(
                                    context, '/notifications'),
                              ),
                              SettingsItem(
                                isFirst: false,
                                isLast: true,
                                title: AppLocalizations.of(context)!
                                    .settingsPageAddressBook,
                                trailingSvgPath: 'assets/icons/book.svg',
                                onTap: () => Navigator.pushNamed(
                                    context, '/address-book'),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _buildSettingsGroup(theme, [
                              SettingsItem(
                                isFirst: true,
                                isLast: false,
                                title: AppLocalizations.of(context)!
                                    .settingsPageSecurityPrivacy,
                                trailingSvgPath: 'assets/icons/shield.svg',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/security'),
                              ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageNetworks,
                                trailingSvgPath: 'assets/icons/globe.svg',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/networks'),
                              ),
                              SettingsItem(
                                isFirst: false,
                                isLast: false,
                                title: AppLocalizations.of(context)!
                                    .settingsPageLanguage,
                                trailingSvgPath: 'assets/icons/language.svg',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/language'),
                              ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageBrowser,
                                trailingSvgPath: 'assets/icons/browser.svg',
                                onTap: () => Navigator.pushNamed(
                                    context, '/browser_settings'),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _buildSettingsGroup(theme, [
                              SettingsItem(
                                isFirst: true,
                                isLast: false,
                                title: AppLocalizations.of(context)!
                                    .settingsPageTelegram,
                                trailingSvgPath: 'assets/icons/telegram.svg',
                                onTap: () => socialMediaService.openTelegram(
                                    username: 'zilpaychat'),
                              ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageTwitter,
                                trailingSvgPath: 'assets/icons/x.svg',
                                onTap: () => socialMediaService.openX(
                                    username: 'pay_zil'),
                              ),
                              SettingsItem(
                                title: AppLocalizations.of(context)!
                                    .settingsPageGitHub,
                                trailingSvgPath: 'assets/icons/github.svg',
                                onTap: () => socialMediaService.openGitHub(
                                  username: 'zilpay',
                                  repository: 'zilpay-mobile',
                                ),
                              ),
                              SettingsItem(
                                isFirst: false,
                                isLast: true,
                                title: AppLocalizations.of(context)!
                                    .settingsPageAbout,
                                trailingSvgPath: 'assets/icons/info.svg',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/about'),
                              ),
                            ]),
                            SizedBox(height: adaptivePadding),
                          ],
                        ),
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

  Widget _buildSettingsGroup(AppTheme theme, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
