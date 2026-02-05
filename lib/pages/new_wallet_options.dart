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
                CustomAppBar(
                  title: l10n.addWalletOptionsTitle,
                  onBackPressed: () => Navigator.pop(context),
                ),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            l10n.addWalletOptionsOtherOptions,
                            style: theme.caption.copyWith(color: theme.textSecondary),
                          ),
                        ),
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
}
