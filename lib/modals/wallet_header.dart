import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/wallet_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/modals/add_bip39_modal_page.dart';
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
    builder: (BuildContext context) {
      return _WalletModalContent(
        onManageWallet: onManageWallet,
      );
    },
  );
}

class _WalletModalContent extends StatefulWidget {
  final VoidCallback? onManageWallet;

  const _WalletModalContent({
    this.onManageWallet,
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
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

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
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final chain = appState.chain;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pushNamed('/', arguments: {
              'selectedIndex': 0,
            });
          },
          child: Container(
            width: 36,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: adaptivePadding),
            decoration: BoxDecoration(
              color: theme.textSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        GestureDetector(
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
                    url: chainIcon(appState.chain!.chain, null),
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorWidget: Blockies(
                      seed: appState.wallet!.walletAddress,
                      color: getWalletColor(0),
                      bgColor: theme.primaryPurple,
                      spotColor: theme.background,
                      size: 8,
                    ),
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
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
            padding: EdgeInsets.symmetric(
              horizontal: adaptivePadding,
              vertical: adaptivePadding,
            ),
            children: appState.wallet!.accounts.asMap().entries.map((entry) {
              final index = entry.key;
              final account = entry.value;
              return WalletCard(
                account: account,
                onTap: () async {
                  final appState =
                      Provider.of<AppState>(context, listen: false);
                  BigInt walletIndex = BigInt.from(appState.selectedWallet);
                  BigInt accountIndex = BigInt.from(index);

                  try {
                    await appState.updateSelectedAccount(
                      walletIndex,
                      accountIndex,
                    );
                  } catch (e) {
                    debugPrint("select wallet error: $e");
                  }
                },
                isSelected:
                    appState.wallet!.selectedAccount == BigInt.from(index),
              );
            }).toList(),
          ),
        ),
        if (!appState.wallet!.walletType.contains(WalletType.SecretKey.name))
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
                    _pushContent(
                      AddNextBip39AccountContent(
                        onBack: _popContent,
                      ),
                    );
                  },
                ),
                if (appState.wallet?.selectedAccount != BigInt.zero)
                  HoverSvgIcon(
                    assetName: "assets/icons/minus.svg",
                    color: theme.danger,
                    width: 40,
                    height: 40,
                    onTap: () async {
                      try {
                        await deleteAccount(
                          walletIndex: BigInt.from(appState.selectedWallet),
                          accountIndex: appState.wallet!.selectedAccount,
                        );
                        await appState.syncData();
                      } catch (e) {
                        debugPrint("try remove account: $e");
                      }
                    },
                  ),
              ],
            ),
          ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
