import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/state/app_state.dart';
import '../components/view_item.dart';

class AddWalletOptionsPage extends StatelessWidget {
  const AddWalletOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              theme.secondaryPurple,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context)!.addWalletOptionsTitle,
            style: TextStyle(color: theme.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletListItem(
                title: AppLocalizations.of(context)!
                    .addWalletOptionsNewWalletTitle,
                subtitle: AppLocalizations.of(context)!
                    .addWalletOptionsNewWalletSubtitle,
                icon: SvgPicture.asset(
                  'assets/icons/add.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/gen_options');
                },
              ),
              WalletListItem(
                title: AppLocalizations.of(context)!
                    .addWalletOptionsExistingWalletTitle,
                subtitle: AppLocalizations.of(context)!
                    .addWalletOptionsExistingWalletSubtitle,
                icon: SvgPicture.asset(
                  'assets/icons/import.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/restore_options');
                },
              ),
              WalletListItem(
                title: AppLocalizations.of(context)!
                    .addWalletOptionsPairWithLedgerTitle,
                subtitle: AppLocalizations.of(context)!
                    .addWalletOptionsPairWithLedgerSubtitle,
                icon: SvgPicture.asset(
                  'assets/icons/ledger.svg',
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/ledger_connect');
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.addWalletOptionsOtherOptions,
                  style: TextStyle(color: theme.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              WalletListItem(
                disabled: true,
                title: AppLocalizations.of(context)!
                    .addWalletOptionsWatchAccountTitle,
                subtitle: AppLocalizations.of(context)!
                    .addWalletOptionsWatchAccountSubtitle,
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
    );
  }
}
