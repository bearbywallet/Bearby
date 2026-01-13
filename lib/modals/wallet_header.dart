import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/wallet_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showWalletModal({
  required BuildContext context,
  VoidCallback? onManageWallet,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (_) => _WalletModalContent(onManageWallet: onManageWallet),
  );
}

class _WalletModalContent extends StatefulWidget {
  final VoidCallback? onManageWallet;

  const _WalletModalContent({this.onManageWallet});

  @override
  State<_WalletModalContent> createState() => _WalletModalContentState();
}

class _WalletModalContentState extends State<_WalletModalContent> {

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.wallet == null) return const SizedBox.shrink();

    return PopScope(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) Navigator.pop(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: appState.currentTheme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border.all(color: appState.currentTheme.modalBorder, width: 2),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: _buildMainContent(appState),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(AppState appState) {
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final wallet = appState.wallet!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: EdgeInsets.symmetric(vertical: adaptivePadding),
          decoration: BoxDecoration(
            color: theme.modalBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        _buildHeader(appState, theme, wallet),
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: wallet.accounts.length,
            padding: EdgeInsets.symmetric(
                horizontal: adaptivePadding, vertical: adaptivePadding),
            itemBuilder: (_, index) => WalletCard(
              account: wallet.accounts[index],
              onTap: () => _selectWallet(index),
              isSelected: wallet.selectedAccount == BigInt.from(index),
            ),
          ),
        ),
        if (!wallet.walletType.contains(WalletType.SecretKey.name))
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: theme.textPrimary.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HoverSvgIcon(
                  assetName: "assets/icons/plus.svg",
                  color: theme.textPrimary,
                  width: 40,
                  height: 40,
                  onTap: () {
                    if (appState.wallet!.walletType
                        .contains(WalletType.ledger.name)) {
                      Navigator.pushNamed(context, "/add_ledger_account",
                          arguments: {
                            "createWallet": false,
                            "chain": appState.chain,
                          });
                    } else {
                      Navigator.pushNamed(context, "/add_account");
                    }
                  },
                ),
                if (wallet.selectedAccount != BigInt.zero)
                  HoverSvgIcon(
                    assetName: "assets/icons/minus.svg",
                    color: theme.danger,
                    width: 40,
                    height: 40,
                    onTap: _deleteSelectedAccount,
                  ),
              ],
            ),
          ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  Widget _buildHeader(AppState appState, AppTheme theme, WalletInfo wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TileButton(
            icon: SvgPicture.asset(
              'assets/icons/lock.svg',
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(
                theme.primaryPurple,
                BlendMode.srcIn,
              ),
            ),
            onPressed: _lockWallet,
            backgroundColor: theme.primaryPurple.withValues(alpha: 0.15),
            textColor: theme.primaryPurple,
            defaultBorderSide: BorderSide(
              color: theme.primaryPurple.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            wallet.walletName,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _lockWallet() {
    Navigator.pop(context);
    widget.onManageWallet?.call();
  }

  Future<void> _selectWallet(int index) async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.updateSelectedAccount(
        BigInt.from(appState.selectedWallet),
        BigInt.from(index),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("select wallet error: $e");
    }
  }

  Future<void> _deleteSelectedAccount() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await deleteAccount(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );
      await appState.syncData();
    } catch (e) {
      debugPrint("try remove account: $e");
    }
  }
}
