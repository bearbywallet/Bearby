import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/view_item.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/state/app_state.dart';

class GenWalletOptionsPage extends StatelessWidget with StatusBarMixin {
  const GenWalletOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

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
                  title: l10n.genWalletOptionsTitle,
                  onBackPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        WalletListItem(
                          title: l10n.genWalletOptionsBIP39Title,
                          subtitle: l10n.genWalletOptionsBIP39Subtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/document.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed('/gen_bip39'),
                        ),
                        WalletListItem(
                          title: l10n.genWalletOptionsPrivateKeyTitle,
                          subtitle: l10n.genWalletOptionsPrivateKeySubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/bincode.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed('/gen_sk'),
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
