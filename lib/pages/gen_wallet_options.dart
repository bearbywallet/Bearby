import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/view_item.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/chain_route_args.dart';
import 'package:bearby/components/wallet_options_shell.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class GenWalletOptionsPage extends StatefulWidget {
  const GenWalletOptionsPage({super.key});

  @override
  State<GenWalletOptionsPage> createState() => _GenWalletOptionsPageState();
}

class _GenWalletOptionsPageState extends State<GenWalletOptionsPage>
    with StatusBarMixin, ChainRouteArgsMixin {
  NetworkConfigInfo? _chain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bootstrapChainArg(_chain, (chain) {
      setState(() {
        _chain = chain;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    final chain = _chain;
    if (chain == null) {
      return const WalletOptionsShell(title: '', loading: true);
    }

    return WalletOptionsShell(
      title: l10n.genWalletOptionsTitle,
      options: [
        WalletListItem(
          title: l10n.genWalletOptionsBIP39Title,
          subtitle: l10n.genWalletOptionsBIP39Subtitle,
          icon: AppIconView(
            icon: AppIcon.document,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => context.push(AppRoutes.genBip39, extra: {'chain': chain}),
        ),
        WalletListItem(
          title: l10n.genWalletOptionsPrivateKeyTitle,
          subtitle: l10n.genWalletOptionsPrivateKeySubtitle,
          disabled: chain.slip44 == kBitcoinlip44,
          icon: AppIconView(
            icon: AppIcon.bincode,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => context.push(AppRoutes.genSk, extra: {'chain': chain}),
        ),
      ],
    );
  }
}