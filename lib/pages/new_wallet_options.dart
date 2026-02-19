import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/view_item.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class AddWalletOptionsPage extends StatefulWidget {
  const AddWalletOptionsPage({super.key});

  @override
  State<AddWalletOptionsPage> createState() => _AddWalletOptionsPageState();
}

class _AddWalletOptionsPageState extends State<AddWalletOptionsPage>
    with StatusBarMixin {
  NetworkConfigInfo? _chain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/net_setup');
      });
    } else {
      setState(() {
        _chain = chain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    if (_chain == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                _buildGlassAppBar(theme, l10n),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        WalletListItem(
                          title: l10n.addWalletOptionsNewWalletTitle,
                          subtitle: l10n.addWalletOptionsNewWalletSubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/add.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/gen_options',
                            arguments: {'chain': _chain},
                          ),
                        ),
                        WalletListItem(
                          title: l10n.addWalletOptionsExistingWalletTitle,
                          subtitle: l10n.addWalletOptionsExistingWalletSubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/import.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/restore_options',
                            arguments: {'chain': _chain},
                          ),
                        ),
                        WalletListItem(
                          title: l10n.addWalletOptionsPairWithLedgerTitle,
                          subtitle: l10n.addWalletOptionsPairWithLedgerSubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/ledger.svg',
                            width: 25,
                            height: 25,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/ledger_connect',
                            arguments: {'chain': _chain},
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(l10n, theme),
                        const SizedBox(height: 16),
                        WalletListItem(
                          disabled: true,
                          title: l10n.addWalletOptionsWatchAccountTitle,
                          subtitle: l10n.addWalletOptionsWatchAccountSubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/looking.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () {},
                        ),
                      ],
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

  Widget _buildGlassAppBar(AppTheme theme, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.cardBackground.withValues(alpha: 0.75),
                theme.cardBackground.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryPurple.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryPurple.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CustomAppBar(
            title: l10n.addWalletOptionsTitle,
            onBackPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppLocalizations l10n, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        l10n.addWalletOptionsOtherOptions,
        style: theme.caption.copyWith(
          color: theme.textSecondary.withValues(alpha: 0.7),
          shadows: [
            Shadow(
              color: theme.primaryPurple.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
