import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/view_item.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/qr_scanner_modal.dart';
import 'package:bearby/src/rust/api/methods.dart';
import 'package:bearby/src/rust/models/keypair.dart';
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
    with StatusBarMixin {
  NetworkConfigInfo? _chain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(AppRoutes.netSetup);
      });
    } else if (_chain == null) {
      setState(() {
        _chain = chain;
      });
    }
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
              if (context.mounted) Navigator.pop(context);
            case QrSecretKind.bip39Mnemonic:
              if (context.mounted) await _processSeedFromQR(context, result.payload!);
            case QrSecretKind.wifPrivateKey:
            case QrSecretKind.hexPrivateKey:
              if (context.mounted) await _processKeyFromQR(context, result.payload!);
            case QrSecretKind.unknown:
              if (context.mounted) Navigator.pop(context);
          }
        } catch (e) {
          debugPrint("QR scanning error: $e");
          if (context.mounted) context.pop();
        }
      },
    );
  }

  Future<void> _processSeedFromQR(BuildContext context, String seed) async {
    final nonEmptyWords =
        seed.split(" ").where((word) => word.isNotEmpty).toList();

    if (nonEmptyWords.isEmpty) {
      if (context.mounted) Navigator.pop(context);
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
      context.pop();
    }
  }

  Future<void> _processKeyFromQR(BuildContext context, String key) async {
    try {
      final KeyPairInfo keys = await keypairFromSk(sk: key);

      if (!context.mounted) return;

      context.push(AppRoutes.passSetup, extra: {'keys': keys, 'chain': _chain});
    } catch (e) {
      debugPrint("Private key processing error: $e");
      if (context.mounted) Navigator.pop(context);
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: l10n.restoreWalletOptionsTitle,
                    onBackPressed: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        WalletListItem(
                          title: l10n.restoreWalletOptionsBIP39Title,
                          subtitle: l10n.restoreWalletOptionsBIP39Subtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/document.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => _handleBip39Restore(context),
                        ),
                        WalletListItem(
                          title: l10n.restoreWalletOptionsPrivateKeyTitle,
                          subtitle: l10n.restoreWalletOptionsPrivateKeySubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/bincode.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => _handlePrivateKeyRestore(context),
                        ),
                        WalletListItem(
                          title: l10n.restoreWalletOptionsKeyStoreTitle,
                          subtitle: l10n.restoreWalletOptionsKeyStoreSubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/file.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => _handleKeystoreResotre(context),
                        ),
                        WalletListItem(
                          title: l10n.restoreWalletOptionsQRCodeTitle,
                          subtitle: l10n.restoreWalletOptionsQRCodeSubtitle,
                          icon: SvgPicture.asset(
                            'assets/icons/qrcode.svg',
                            width: 35,
                            height: 35,
                            colorFilter: ColorFilter.mode(
                              theme.primaryPurple,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () => _handleQRCodeScanning(context),
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
