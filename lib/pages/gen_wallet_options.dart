import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/state/app_state.dart';
import '../components/view_item.dart';

class GenWalletOptionsPage extends StatelessWidget {
  const GenWalletOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: StatusBarUtils.getOverlayStyle(context),
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
        title: Text(AppLocalizations.of(context)!.genWalletOptionsTitle,
            style: TextStyle(color: theme.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletListItem(
                title: AppLocalizations.of(context)!.genWalletOptionsBIP39Title,
                subtitle:
                    AppLocalizations.of(context)!.genWalletOptionsBIP39Subtitle,
                icon: SvgPicture.asset(
                  'assets/icons/document.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/gen_bip39');
                },
              ),
              WalletListItem(
                title: AppLocalizations.of(context)!
                    .genWalletOptionsPrivateKeyTitle,
                subtitle: AppLocalizations.of(context)!
                    .genWalletOptionsPrivateKeySubtitle,
                icon: SvgPicture.asset(
                  'assets/icons/bincode.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/gen_sk');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
