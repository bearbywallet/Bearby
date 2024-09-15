import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/action_button.dart';
import '../components/crypto_list.dart';
import '../components/hoverd_svg.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              SizedBox(height: 20),
              _buildTotalBalance(theme),
              SizedBox(height: 20),
              _buildActionButtons(),
              SizedBox(height: 20),
              _buildCryptoList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: 8),
            Text(
              'Main wallet',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        HoverSvgIcon(
          assetName: 'assets/icons/gear.svg',
          width: 30,
          height: 30,
          onTap: () {
            print('Settings tapped');
          },
        ),
      ],
    );
  }

  Widget _buildTotalBalance(AppTheme theme) {
    return Text(
      '\$ 9467.65',
      style: TextStyle(
        color: theme.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomActionButton(
          label: 'Send',
          iconPath: 'assets/icons/send.svg',
          onPressed: () {
            // Handle send action
          },
        ),
        CustomActionButton(
          label: 'Receive',
          iconPath: 'assets/icons/receive.svg',
          onPressed: () {
            // Handle receive action
          },
        ),
        CustomActionButton(
          label: 'Swap',
          iconPath: 'assets/icons/swap.svg',
          onPressed: () {
            // Handle swap action
          },
        ),
        CustomActionButton(
          label: 'Buy',
          iconPath: 'assets/icons/buy.svg',
          onPressed: () {
            // Handle buy action
          },
        ),
      ],
    );
  }

  Widget _buildCryptoList() {
    return CryptoList(
      items: [
        CryptoListItem(
          name: 'Ethereum (ETH)',
          balance: '2148',
          balanceInUsd: '\$ 2148',
          icons: [
            SvgPicture.asset('assets/icons/eth.svg', width: 16, height: 16),
            SizedBox(width: 4),
            SvgPicture.asset('assets/icons/icon1.svg', width: 16, height: 16),
            SizedBox(width: 4),
            SvgPicture.asset('assets/icons/icon2.svg', width: 16, height: 16),
          ],
        ),
        CryptoListItem(
          name: 'Zilliqa',
          balance: '7333',
          balanceInUsd: '\$ 7333',
          icons: [
            SvgPicture.asset('assets/icons/zil.svg', width: 16, height: 16),
            SizedBox(width: 4),
            SvgPicture.asset('assets/icons/icon3.svg', width: 16, height: 16),
          ],
        ),
        CryptoListItem(
          name: 'Binance',
          balance: '8521',
          balanceInUsd: '\$ 8521',
          icons: [
            SvgPicture.asset('assets/icons/bnb.svg', width: 16, height: 16),
            SizedBox(width: 4),
            SvgPicture.asset('assets/icons/icon4.svg', width: 16, height: 16),
            SizedBox(width: 4),
            SvgPicture.asset('assets/icons/icon5.svg', width: 16, height: 16),
          ],
        ),
      ],
    );
  }
}
