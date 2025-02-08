import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/config/providers.dart';
import 'package:zilpay/mixins/qrcode.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';
import '../components/view_item.dart';

class RestoreWalletOptionsPage extends StatelessWidget {
  const RestoreWalletOptionsPage({super.key});

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
        title:
            Text('Restore Wallet', style: TextStyle(color: theme.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletListItem(
                title: 'BIP39',
                subtitle: 'Restore with Mnemonic phrase',
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
                  Navigator.of(context).pushNamed('/restore_bip39');
                },
              ),
              WalletListItem(
                disabled: true,
                title: 'SLIP-0039',
                subtitle: 'Restore with Shared Mnemonic phrase',
                icon: SvgPicture.asset(
                  'assets/icons/puzzle.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {/* Handle SLIP-0039 restoration */},
              ),
              WalletListItem(
                title: 'Private Key',
                subtitle: 'Restore with private key',
                icon: SvgPicture.asset(
                  'assets/icons/bincode.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {/* Handle private key restoration */},
              ),
              WalletListItem(
                title: 'QRcode',
                subtitle: 'Restore wallet by QRcode scanning',
                icon: SvgPicture.asset(
                  'assets/icons/qrcode.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {
                  showQRScannerModal(
                    context: context,
                    onScanned: (String qrData) async {
                      final values = parseQRSecretData(qrData);
                      String? shortName = values['chain'];
                      String? seed = values['seed'];
                      String? key = values['key'];

                      if (shortName == null) {
                        Navigator.pop(context);
                        return;
                      }

                      final String mainnetJsonData = await rootBundle
                          .loadString('assets/chains/mainnet-chains.json');
                      final List<Chain> mainnetChains =
                          await ChainService.loadChains(mainnetJsonData);

                      if (!mainnetChains
                          .any((chain) => chain.shortName == shortName)) {
                        Navigator.pop(context);
                        return;
                      }

                      if (seed != null) {
                        try {
                          final nonEmptyWords = seed
                              .split(" ")
                              .where((word) => word.isNotEmpty)
                              .toList();

                          if (nonEmptyWords.isEmpty) {
                            Navigator.pop(context);

                            return;
                          }

                          List<int> errorIndexes =
                              (await checkNotExistsBip39Words(
                            words: nonEmptyWords,
                            lang: 'english',
                          ))
                                  .map((e) => e.toInt())
                                  .toList();

                          if (errorIndexes.isEmpty) {
                            Navigator.of(context).pushNamed('/net_setup',
                                arguments: {
                                  'bip39': nonEmptyWords,
                                  'shortName': shortName
                                });
                          } else {
                            // TODO: maybe error hanlder.
                            Navigator.pop<void>(context);
                          }
                        } catch (e) {
                          debugPrint("error: $e");
                        }
                      } else if (key != null) {
                        try {
                          KeyPairInfo keys = await keypairFromSk(sk: key);
                          Navigator.of(context).pushNamed('/net_setup',
                              arguments: {
                                'keys': keys,
                                'shortName': shortName
                              });
                          return;
                        } catch (e) {
                          debugPrint("error: $e");
                          Navigator.pop(context);
                          return;
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
