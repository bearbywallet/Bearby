import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showBrowserActionModal({
  required BuildContext context,
  required VoidCallback onRefresh,
  required VoidCallback onCopyLink,
  required VoidCallback onShare,
  required bool isConnected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => BrowserActionModal(
      onRefresh: onRefresh,
      onCopyLink: onCopyLink,
      onShare: onShare,
      isConnected: isConnected,
    ),
  );
}

class BrowserActionModal extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onCopyLink;
  final VoidCallback onShare;
  final bool isConnected;

  const BrowserActionModal({
    super.key,
    required this.onRefresh,
    required this.onCopyLink,
    required this.onShare,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(adaptivePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(theme),
              const SizedBox(height: 16),
              _buildAccountInfo(appState, theme),
              const SizedBox(height: 24),
              _buildActionGrid(context, theme, l10n),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(AppTheme theme) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildAccountInfo(AppState appState, AppTheme theme) {
    final account = appState.account;
    if (account == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        AvatarAddress(avatarSize: 50, account: account),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    account.name,
                    style: theme.bodyText1.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isConnected)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              CopyContent(address: account.addr, isShort: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(
      BuildContext context, AppTheme theme, AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionButton(
          theme: theme,
          iconPath: 'assets/icons/reload.svg',
          label: l10n.browserActionMenuRefresh,
          onTap: () {
            onRefresh();
            Navigator.pop(context);
          },
        ),
        _buildActionButton(
          theme: theme,
          iconPath: 'assets/icons/copy.svg',
          label: l10n.browserActionMenuCopyLink,
          onTap: () {
            onCopyLink();
            Navigator.pop(context);
          },
        ),
        _buildActionButton(
          theme: theme,
          iconPath: 'assets/icons/share.svg',
          label: l10n.browserActionMenuShare,
          onTap: () {
            onShare();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required AppTheme theme,
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HoverSvgIcon(
          assetName: iconPath,
          width: 28,
          height: 28,
          onTap: onTap,
          color: theme.textPrimary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.caption.copyWith(color: theme.textSecondary),
        ),
      ],
    );
  }
}
