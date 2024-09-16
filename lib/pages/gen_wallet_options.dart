import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/theme_provider.dart';
import '../components/view_item.dart';

class GenWalletOptionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
            color: theme.secondaryPurple,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Generate Wallet', style: TextStyle(color: theme.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletListItem(
                title: 'BIP39',
                subtitle: 'Generate Mnemonic phrase',
                icon: SvgPicture.asset(
                  'assets/icons/document.svg',
                  width: 35,
                  height: 35,
                  color: theme.primaryPurple,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/gen_bip39');
                },
              ),
              WalletListItem(
                title: 'SLIP-0039',
                subtitle: 'Generate Mnemonic phrase with share',
                icon: SvgPicture.asset(
                  'assets/icons/puzzle.svg',
                  width: 35,
                  height: 35,
                  color: theme.primaryPurple,
                ),
                onTap: () {/* Handle SLIP-0039 generation */},
              ),
              WalletListItem(
                title: 'Private Key',
                subtitle: 'Generate just one private key',
                icon: SvgPicture.asset(
                  'assets/icons/bincode.svg',
                  width: 35,
                  height: 35,
                  color: theme.primaryPurple,
                ),
                onTap: () {/* Handle private key generation */},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
