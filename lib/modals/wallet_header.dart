import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/wallet_card.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/theme_provider.dart';

void showWalletModal({
  required BuildContext context,
  VoidCallback? onManageWallet,
  VoidCallback? onAddWallet,
  Function(int)? onWalletSelect,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      final theme = Provider.of<ThemeProvider>(context).currentTheme;
      final appState = Provider.of<AppState>(context);

      if (appState.wallet == null) {
        return Container();
      }

      final double headerHeight = 150;
      final double footerHeight = 84;
      final double walletCardHeight = 72;
      final double bottomPadding = MediaQuery.of(context).padding.bottom;
      final double contentHeight = headerHeight +
          (walletCardHeight * appState.wallet!.accounts.length) +
          footerHeight +
          bottomPadding;

      final double screenHeight = MediaQuery.of(context).size.height;
      final double initialChildSize =
          (contentHeight / screenHeight).clamp(0.3, 0.85);

      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: 0.3,
        maxChildSize: 0.70,
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onManageWallet,
                  child: Column(
                    children: [
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
                            seed: appState.wallet!.walletAddress,
                            color: getWalletColor(0),
                            bgColor: theme.primaryPurple,
                            spotColor: theme.background,
                            size: 8,
                          ),
                        ),
                      ),
                      Text(
                        appState.wallet!.walletName,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    children:
                        appState.wallet!.accounts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final account = entry.value;
                      return WalletCard(
                        name: account.name,
                        address: shortenAddress(account.addr),
                        balance: '0.00',
                        onTap: () => onWalletSelect?.call(index),
                        isSelected: appState.selectedWallet == index,
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: onAddWallet,
                    borderRadius: BorderRadius.circular(16),
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
