import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/wallet_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';

void showWalletModal({
  required BuildContext context,
  VoidCallback? onManageWallet,
  Function(int)? onWalletSelect,
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
    final appState = Provider.of<AppState>(context);
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
          ),
          child: SingleChildScrollView(
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final chain = appState.chain;
    final wallet = appState.wallet!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(theme, adaptivePadding),
        _buildWalletHeader(
            theme, chain, wallet.walletName, wallet.walletAddress),
        _buildAccountsList(adaptivePadding, wallet),
        if (!wallet.walletType.contains(WalletType.SecretKey.name))
          _buildActionButtons(theme, wallet),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildDragHandle(dynamic theme, double adaptivePadding) {
    return Container(
      width: 36,
      height: 4,
      margin: EdgeInsets.symmetric(vertical: adaptivePadding),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildWalletHeader(
      dynamic theme, dynamic chain, String walletName, String walletAddress) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onManageWallet,
      child: Column(
        children: [
          if (chain != null)
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryPurple.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: AsyncImage(
                url: preprocessUrl(chain.logo, theme.value),
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorWidget: Blockies(
                  seed: walletAddress,
                  color: theme.secondaryPurple,
                  bgColor: theme.primaryPurple,
                  spotColor: theme.background,
                  size: 8,
                ),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
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
        ],
      ),
    );
  }

  Widget _buildAccountsList(double adaptivePadding, dynamic wallet) {
    final accounts = wallet.accounts;
    final selectedAccount = wallet.selectedAccount;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: accounts.length,
        padding: EdgeInsets.symmetric(
          horizontal: adaptivePadding,
          vertical: adaptivePadding,
        ),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return WalletCard(
            account: account,
            onTap: () => _selectWallet(index),
            isSelected: selectedAccount == BigInt.from(index),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(dynamic theme, dynamic wallet) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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
              if (mounted) {
                Navigator.of(context).pushNamed("/add_account");
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
    );
  }

  Future<void> _selectWallet(int index) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletIndex = BigInt.from(appState.selectedWallet);
    final accountIndex = BigInt.from(index);

    try {
      await appState.updateSelectedAccount(walletIndex, accountIndex);
      if (mounted) Navigator.of(context).pop<void>();
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
