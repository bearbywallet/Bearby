import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/tile_button.dart';
import 'package:bearby/components/wallet_card.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/wallet.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

void showWalletModal({
  required BuildContext context,
  VoidCallback? onManageAccount,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (_) => const _WalletModalContent(),
  );
}

class _WalletModalContent extends StatefulWidget {
  const _WalletModalContent();

  @override
  State<_WalletModalContent> createState() => _WalletModalContentState();
}

class _WalletModalContentState extends State<_WalletModalContent> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final wallet = appState.wallet;
        if (wallet == null) return const SizedBox.shrink();

        final theme = appState.currentTheme;

        return PopScope(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 0) {
                Navigator.pop(context);
              }
            },
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.cardBackground.withValues(alpha: 0.88),
                          theme.cardBackground.withValues(alpha: 0.96),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: theme.textSecondary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryPurple.withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _buildMainContent(context, appState, theme, wallet),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AppState appState,
    AppTheme theme,
    WalletInfo wallet,
  ) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final accounts = appState.accounts;
    final selected = wallet.selectedAccount;
    final isSecretKey = wallet.walletType.contains(WalletType.SecretKey.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(theme),
        _buildHeader(theme, wallet),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: adaptivePadding,
                vertical: 6,
              ),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final account = accounts[index];
                final isSelected = selected == BigInt.from(index);
                final canDelete =
                    !isSecretKey && accounts.length > 1 && index > 0;

                final card = WalletCard(
                  key: ValueKey('wallet_acc_${index}_${account.addr}'),
                  account: account,
                  isSelected: isSelected,
                  onTap: () => _selectWallet(index),
                  onDelete:
                      canDelete ? () => _deleteAccountAt(index) : null,
                );

                if (!canDelete) {
                  return card;
                }

                return Dismissible(
                  key: ValueKey('dismiss_acc_${index}_${account.addr}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _deleteAccountAt(index);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.danger.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: AppIconView(
                      icon: AppIcon.minus,
                      color: theme.danger,
                      size: 18,
                    ),
                  ),
                  child: card,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!isSecretKey)
          _buildBottomActions(context, theme, appState, wallet),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  Widget _buildHandle(AppTheme theme) {
    return Container(
      width: 48,
      height: 5,
      margin: const EdgeInsets.only(top: 14, bottom: 10),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, WalletInfo wallet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TileButton(
            icon: AppIconView(
              icon: AppIcon.lock,
              color: theme.primaryPurple,
              size: 24,
            ),
            onPressed: () {
              _lockWallet();
              Navigator.pop(context);
            },
            backgroundColor: theme.primaryPurple.withValues(alpha: 0.15),
            textColor: theme.primaryPurple,
          ),
          const SizedBox(height: 6),
          Text(
            wallet.walletName,
            style: theme.titleLarge.copyWith(
              color: theme.textSecondary,
              shadows: [
                Shadow(
                  blurRadius: 8.0,
                  color: theme.primaryPurple.withValues(alpha: 0.2),
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    AppTheme theme,
    AppState appState,
    WalletInfo wallet,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.primaryPurple.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            final isLedger =
                wallet.walletType.contains(WalletType.ledger.name);
            final chain = appState.chain;
            Navigator.pop(context);
            if (isLedger) {
              context.push(AppRoutes.addLedgerAccount, extra: {
                "createWallet": false,
                "chain": chain,
              });
            } else {
              context.push(AppRoutes.addAccount);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryPurple.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryPurple.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconView(
                  icon: AppIcon.plus,
                  color: theme.primaryPurple,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.addAccountPageTitle,
                  style: theme.bodyText2.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _lockWallet() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.clearAuthentication();
  }

  Future<void> _selectWallet(int index) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentSelected = appState.wallet?.selectedAccount;
    final target = BigInt.from(index);

    HapticFeedback.selectionClick();
    if (mounted) {
      Navigator.pop(context);
    }

    if (currentSelected == target) {
      return;
    }

    try {
      await appState.updateSelectedAccount(
        appState.selectedWalletIndex,
        target,
      );
      await appState.refreshBalancesAndRates(
        walletIndex: appState.selectedWalletIndex,
      );
    } catch (e) {
      debugPrint("select wallet error: $e");
    }
  }

  Future<void> _deleteAccountAt(int index) async {
    if (_isDeleting || index <= 0) {
      return;
    }
    final appState = Provider.of<AppState>(context, listen: false);
    _isDeleting = true;
    try {
      await deleteAccount(
        walletIndex: appState.selectedWalletIndex,
        accountIndex: BigInt.from(index),
      );
      await appState.syncWalletState();
    } catch (e) {
      debugPrint("try remove account: $e");
    } finally {
      _isDeleting = false;
    }
  }
}
