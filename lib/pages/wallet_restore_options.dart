import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/mixins/qrcode.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';
import '../components/view_item.dart';

class RestoreWalletOptionsPage extends StatelessWidget {
  const RestoreWalletOptionsPage({super.key});

  void _handleBip39Restore(BuildContext context) {
    Navigator.of(context).pushNamed('/restore_bip39');
  }

  void _handlePrivateKeyRestore(BuildContext context) {
    // Implementation for private key restoration
  }

  void _handleQRCodeScanning(BuildContext context) {
    showQRScannerModal(
      context: context,
      onScanned: (String qrData) async {
        try {
          final words =
              qrData.split(' ').where((word) => word.isNotEmpty).toList();
          final wordCount = words.length;
          if ([12, 15, 18, 21, 24].contains(wordCount)) {
            final errorIndexes =
                (await checkNotExistsBip39Words(words: words, lang: 'english'))
                    .map((e) => e.toInt())
                    .toList();
            if (errorIndexes.isEmpty && context.mounted) {
              Navigator.of(context).pushNamed('/net_setup',
                  arguments: {'bip39': words, 'shortName': null});
            } else if (context.mounted) {
              Navigator.pop(context);
            }
          } else {
            final values = parseQRSecretData(qrData);
            final String? shortName = values['chain'];
            final String? seed = values['seed'];
            final String? key = values['key'];
            if (shortName == null || !context.mounted) {
              if (context.mounted) Navigator.pop(context);
              return;
            }
            final mainnetJsonData = await rootBundle
                .loadString('assets/chains/mainnet-chains.json');
            final mainnetChains =
                await getChainsProvidersFromJson(jsonStr: mainnetJsonData);
            if (!mainnetChains.any((chain) => chain.shortName == shortName) ||
                !context.mounted) {
              if (context.mounted) Navigator.pop(context);
              return;
            }
            if (seed != null && context.mounted) {
              await _processSeedFromQR(context, seed, shortName);
            } else if (key != null && context.mounted) {
              await _processKeyFromQR(context, key, shortName);
            } else if (context.mounted) {
              Navigator.pop(context);
            }
          }
        } catch (e) {
          debugPrint("QR scanning error: $e");
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _processSeedFromQR(
      BuildContext context, String seed, String shortName) async {
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
      Navigator.of(context).pushNamed(
        '/net_setup',
        arguments: {'bip39': nonEmptyWords, 'shortName': shortName},
      );
    } else {
      Navigator.pop<void>(context);
    }
  }

  Future<void> _processKeyFromQR(
      BuildContext context, String key, String shortName) async {
    try {
      final KeyPairInfo keys = await keypairFromSk(sk: key);

      // Check if the context is still valid after the async operation
      if (!context.mounted) return;

      Navigator.of(context).pushNamed(
        '/net_setup',
        arguments: {'keys': keys, 'shortName': shortName},
      );
    } catch (e) {
      debugPrint("Private key processing error: $e");
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    // Pre-construct icons to avoid rebuilding them on every frame
    final backIcon = SvgPicture.asset(
      'assets/icons/back.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        theme.secondaryPurple,
        BlendMode.srcIn,
      ),
    );

    final documentIcon = SvgPicture.asset(
      'assets/icons/document.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        theme.primaryPurple,
        BlendMode.srcIn,
      ),
    );

    final puzzleIcon = SvgPicture.asset(
      'assets/icons/puzzle.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        theme.primaryPurple,
        BlendMode.srcIn,
      ),
    );

    final bincodeIcon = SvgPicture.asset(
      'assets/icons/bincode.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        theme.primaryPurple,
        BlendMode.srcIn,
      ),
    );

    final qrcodeIcon = SvgPicture.asset(
      'assets/icons/qrcode.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        theme.primaryPurple,
        BlendMode.srcIn,
      ),
    );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: backIcon,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Restore Wallet',
          style: TextStyle(color: theme.textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            WalletListItem(
              title: 'BIP39',
              subtitle: 'Restore with Mnemonic phrase',
              icon: documentIcon,
              onTap: () => _handleBip39Restore(context),
            ),
            WalletListItem(
              disabled: true,
              title: 'SLIP-0039',
              subtitle: 'Restore with Shared Mnemonic phrase',
              icon: puzzleIcon,
              onTap: null,
            ),
            WalletListItem(
              title: 'Private Key',
              subtitle: 'Restore with private key',
              icon: bincodeIcon,
              onTap: () => _handlePrivateKeyRestore(context),
            ),
            WalletListItem(
              title: 'QRcode',
              subtitle: 'Restore wallet by QRcode scanning',
              icon: qrcodeIcon,
              onTap: () => _handleQRCodeScanning(context),
            ),
          ],
        ),
      ),
    );
  }
}
