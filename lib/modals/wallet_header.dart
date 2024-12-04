import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/wallet_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/modals/add_bip39_modal_page.dart';
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
      return _WalletModalContent(
        onManageWallet: onManageWallet,
        onAddWallet: onAddWallet,
        onWalletSelect: onWalletSelect,
      );
    },
  );
}

class _WalletModalContent extends StatefulWidget {
  final VoidCallback? onManageWallet;
  final VoidCallback? onAddWallet;
  final Function(int)? onWalletSelect;

  const _WalletModalContent({
    this.onManageWallet,
    this.onAddWallet,
    this.onWalletSelect,
  });

  @override
  State<_WalletModalContent> createState() => _WalletModalContentState();
}

class _WalletModalContentState extends State<_WalletModalContent> {
  final List<Widget> _contentStack = [];

  void _pushContent(Widget content) {
    setState(() {
      _contentStack.add(content);
    });
  }

  void _popContent() {
    if (_contentStack.isNotEmpty) {
      setState(() {
        _contentStack.removeLast();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final appState = Provider.of<AppState>(context);

    if (appState.wallet == null) {
      return Container();
    }

    return PopScope(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _popContent();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: _contentStack.isNotEmpty
                ? _contentStack.last
                : _buildMainContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final appState = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: adaptivePadding),
            decoration: BoxDecoration(
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onManageWallet,
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
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            children: appState.wallet!.accounts.asMap().entries.map((entry) {
              final index = entry.key;
              final account = entry.value;
              return WalletCard(
                name: account.name,
                address:
                    shortenAddress(account.addr, leftSize: 8, rightSize: 8),
                balance: '0.00',
                onTap: () => widget.onWalletSelect?.call(index),
                isSelected:
                    appState.wallet!.selectedAccount == BigInt.from(index),
              );
            }).toList(),
          ),
        ),
        if (!appState.wallet!.walletType.contains(WalletType.SecretKey.name))
          Padding(
            padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
            child: InkWell(
              onTap: () {
                _pushContent(
                  AddNextBip39AccountContent(
                    onBack: _popContent,
                  ),
                );
              },
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
    );
  }
}
