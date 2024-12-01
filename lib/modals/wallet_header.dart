import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/components/wallet_card.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/theme/theme_provider.dart';

void showWalletModal({
  required BuildContext context,
  required String walletName,
  required String walletAddress,
  VoidCallback? onManageWallet,
  VoidCallback? onAddWallet,
  Function(String)? onWalletSelect,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    builder: (BuildContext context) {
      final theme = Provider.of<ThemeProvider>(context).currentTheme;

      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primaryPurple.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Blockies(
                      seed: walletAddress,
                      color: getWalletColor(0),
                      bgColor: theme.primaryPurple,
                      spotColor: theme.background,
                      size: 8,
                    ),
                  ),
                ),
                Text(
                  walletName,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CopyAddressButton(
                    address: walletAddress,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onManageWallet,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: theme.textPrimary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Manage wallet',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    children: [
                      WalletCard(
                        name: 'Wallet 1',
                        address: '0x22d9...a1cD',
                        balance: '\$0.00',
                        onTap: () => onWalletSelect?.call('0x22d9...a1cD'),
                        isSelected: false,
                      ),
                      WalletCard(
                        name: 'Wallet 2',
                        address: '0x79e8...234B',
                        balance: '\$0.00',
                        onTap: () => onWalletSelect?.call('0x79e8...234B'),
                        isSelected: false,
                      ),
                      WalletCard(
                        name: 'Wallet 3',
                        address: '0xB941...3bF2',
                        balance: '\$0.00',
                        onTap: () => onWalletSelect?.call('0xB941...3bF2'),
                        isSelected: false,
                      ),
                      WalletCard(
                        name: 'Wallet 4',
                        address: '0xE842...C9A4',
                        balance: '\$0.00',
                        onTap: () => onWalletSelect?.call('0xE842...C9A4'),
                        isSelected: false,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: onAddWallet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.textPrimary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.textPrimary.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/plus.svg',
                                width: 20,
                                height: 20,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      );
    },
  );
}
