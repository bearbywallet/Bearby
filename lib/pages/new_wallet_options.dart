import 'package:flutter/material.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/view_item.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/chain_route_args.dart';
import 'package:bearby/components/wallet_options_shell.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class AddWalletOptionsPage extends StatefulWidget {
  const AddWalletOptionsPage({super.key});

  @override
  State<AddWalletOptionsPage> createState() => _AddWalletOptionsPageState();
}

class _AddWalletOptionsPageState extends State<AddWalletOptionsPage>
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
      title: l10n.addWalletOptionsTitle,
      options: [
        WalletListItem(
          title: l10n.addWalletOptionsNewWalletTitle,
          subtitle: l10n.addWalletOptionsNewWalletSubtitle,
          icon: AppIconView(
            icon: AppIcon.add,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => context.push(AppRoutes.genOptions, extra: {'chain': chain}),
        ),
        WalletListItem(
          title: l10n.addWalletOptionsExistingWalletTitle,
          subtitle: l10n.addWalletOptionsExistingWalletSubtitle,
          icon: AppIconView(
            icon: AppIcon.importWallet,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () =>
              context.push(AppRoutes.restoreOptions, extra: {'chain': chain}),
        ),
        WalletListItem(
          title: l10n.addWalletOptionsPairWithLedgerTitle,
          subtitle: l10n.addWalletOptionsPairWithLedgerSubtitle,
          icon: AppIconView(
            icon: AppIcon.ledger,
            size: 25,
            color: theme.primaryPurple,
          ),
          onTap: () =>
              context.push(AppRoutes.ledgerConnect, extra: {'chain': chain}),
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
          icon: AppIconView(
            icon: AppIcon.looking,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () {},
        ),
      ],
    );
  }
}