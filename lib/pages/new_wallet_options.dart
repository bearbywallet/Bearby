import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        title: Text('Add Wallet', style: TextStyle(color: theme.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletListItem(
                title: 'New Wallet',
                subtitle: 'Create new wallet',
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
                title: 'Existing Wallet',
                subtitle: 'Import wallet with a 24 secret recovery words',
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
                title: 'Pair with Ledger',
                subtitle: 'Hardware module, Bluetooth',
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
                  'Other options',
                  style: TextStyle(color: theme.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              WalletListItem(
                disabled: true,
                title: 'Watch Account',
                subtitle: 'For monitor wallet activity without recovery phrase',
                icon: SvgPicture.asset(
                  'assets/icons/looking.svg',
                  width: 35,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {/* Handle watch account */},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
