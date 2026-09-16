import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/view_item.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/chain_route_args.dart';
import 'package:bearby/components/wallet_options_shell.dart';
import 'package:bearby/modals/qr_scanner_modal.dart';
import 'package:bearby/src/rust/api/methods.dart';
import 'package:bearby/src/rust/models/keypair.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class RestoreWalletOptionsPage extends StatefulWidget {
  const RestoreWalletOptionsPage({super.key});

  @override
  State<RestoreWalletOptionsPage> createState() =>
      _RestoreWalletOptionsPageState();
}

class _RestoreWalletOptionsPageState extends State<RestoreWalletOptionsPage>
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

  void _handleBip39Restore(BuildContext context) {
    context.push(AppRoutes.restoreBip39, extra: {'chain': _chain});
  }

  void _handlePrivateKeyRestore(BuildContext context) {
    context.push(AppRoutes.restoreSk, extra: {'chain': _chain});
  }

  void _handleKeystoreResotre(BuildContext context) {
    context.push(AppRoutes.keystoreFileRestore, extra: {'chain': _chain});
  }

  void _showQrError(BuildContext ctx, String message) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
    ctx.pop();
  }

  void _handleQRCodeScanning(BuildContext context) {
    showQRScannerModal(
      context: context,
      onScanned: (String qrData) async {
        try {
          final result = parseAnyQrSecret(qrData);
          switch (result.kind) {
            case QrSecretKind.bearby:
              final values = parseQRSecretData(qrData);
              final seed = values['seed'];
              final key = values['key'];
              if (seed != null && context.mounted) {
                await _processSeedFromQR(context, seed);
                return;
              }
              if (key != null && context.mounted) {
                await _processKeyFromQR(context, key);
                return;
              }
              if (context.mounted) _showQrError(context, AppLocalizations.of(context)!.qrCodeUnrecognizedError);
            case QrSecretKind.bip39Mnemonic:
              if (context.mounted) await _processSeedFromQR(context, result.payload!);
            case QrSecretKind.wifPrivateKey:
            case QrSecretKind.hexPrivateKey:
              if (context.mounted) await _processKeyFromQR(context, result.payload!);
            case QrSecretKind.unknown:
              if (context.mounted) _showQrError(context, AppLocalizations.of(context)!.qrCodeUnrecognizedError);
          }
        } catch (e) {
          debugPrint("QR scanning error: $e");
          if (context.mounted) _showQrError(context, AppLocalizations.of(context)!.qrCodeScanError);
        }
      },
    );
  }

  Future<void> _processSeedFromQR(BuildContext context, String seed) async {
    final nonEmptyWords =
        seed.split(" ").where((word) => word.isNotEmpty).toList();

    if (nonEmptyWords.isEmpty) {
      if (context.mounted) _showQrError(context, AppLocalizations.of(context)!.qrCodeEmptySeedError);
      return;
    }

    final List<int> errorIndexes = (await checkNotExistsBip39Words(
      words: nonEmptyWords,
      lang: 'english',
    ))
        .map((e) => e.toInt())
        .toList();

    if (!context.mounted) return;

    if (errorIndexes.isEmpty) {
      context.push(AppRoutes.passSetup, extra: {'bip39': nonEmptyWords, 'chain': _chain});
    } else {
      _showQrError(context, AppLocalizations.of(context)!.qrCodeInvalidWordsError);
    }
  }

  Future<void> _processKeyFromQR(BuildContext context, String key) async {
    try {
      final KeyPairInfo keys = await keypairFromSk(sk: key);

      if (!context.mounted) return;

      context.push(AppRoutes.passSetup, extra: {'keys': keys, 'chain': _chain});
    } catch (e) {
      debugPrint("Private key processing error: $e");
      if (context.mounted) _showQrError(context, AppLocalizations.of(context)!.qrCodeInvalidKeyError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    final chain = _chain;
    if (chain == null) {
      return const WalletOptionsShell(title: '', loading: true);
    }

    final isBitcoinChain = chain.slip44 == kBitcoinlip44;

    return WalletOptionsShell(
      title: l10n.restoreWalletOptionsTitle,
      options: [
        WalletListItem(
          title: l10n.restoreWalletOptionsBIP39Title,
          subtitle: l10n.restoreWalletOptionsBIP39Subtitle,
          icon: AppIconView(
            icon: AppIcon.document,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => _handleBip39Restore(context),
        ),
        WalletListItem(
          title: isBitcoinChain
              ? '${l10n.restoreWalletOptionsPrivateKeyTitle} ${l10n.deprecatedLabel}'
              : l10n.restoreWalletOptionsPrivateKeyTitle,
          subtitle: isBitcoinChain
              ? l10n.restoreWalletOptionsPrivateKeyDeprecatedSubtitle
              : l10n.restoreWalletOptionsPrivateKeySubtitle,
          icon: AppIconView(
            icon: AppIcon.bincode,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => _handlePrivateKeyRestore(context),
        ),
        WalletListItem(
          title: l10n.restoreWalletOptionsKeyStoreTitle,
          subtitle: l10n.restoreWalletOptionsKeyStoreSubtitle,
          icon: AppIconView(
            icon: AppIcon.file,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => _handleKeystoreResotre(context),
        ),
        WalletListItem(
          title: l10n.restoreWalletOptionsQRCodeTitle,
          subtitle: l10n.restoreWalletOptionsQRCodeSubtitle,
          icon: AppIconView(
            icon: AppIcon.scan,
            size: 35,
            color: theme.primaryPurple,
          ),
          onTap: () => _handleQRCodeScanning(context),
        ),
      ],
    );
  }
}
