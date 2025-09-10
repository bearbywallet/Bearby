import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class BrowserActionMenu extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onCopyLink;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final BuildContext parentContext;

  const BrowserActionMenu({
    super.key,
    required this.onShare,
    required this.onCopyLink,
    required this.onClose,
    this.onBack,
    this.onForward,
    required this.parentContext,
  });

  void _showMenu() {
    final appState = Provider.of<AppState>(parentContext, listen: false);
    final theme = appState.currentTheme;

    showDialog<void>(
      context: parentContext,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          insetPadding: const EdgeInsets.all(0),
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(top: 5, right: 5),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onBack!();
                            },
                            icon: SvgPicture.asset(
                              "assets/icons/back.svg",
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onForward!();
                            },
                            icon: SvgPicture.asset(
                              "assets/icons/forward.svg",
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildDivider(theme),
                    _buildMenuItem(
                      context,
                      AppLocalizations.of(context)!.browserActionMenuShare,
                      'assets/icons/share.svg',
                      onShare,
                      theme,
                    ),
                    _buildDivider(theme),
                    _buildMenuItem(
                      context,
                      AppLocalizations.of(context)!.browserActionMenuCopyLink,
                      'assets/icons/copy.svg',
                      onCopyLink,
                      theme,
                    ),
                    _buildDivider(theme),
                    _buildMenuItem(
                      context,
                      AppLocalizations.of(context)!.browserActionMenuClose,
                      'assets/icons/close.svg',
                      onClose,
                      theme,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String icon,
    VoidCallback onTap,
    AppTheme theme,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            HoverSvgIcon(
              assetName: icon,
              width: 20,
              height: 20,
              color: theme.textPrimary,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.bodyText2.copyWith(
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(AppTheme theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.textSecondary.withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Provider.of<AppState>(parentContext, listen: false).currentTheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HoverSvgIcon(
            assetName: 'assets/icons/dots.svg',
            width: 24,
            height: 24,
            onTap: _showMenu,
            color: theme.textPrimary,
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 40,
            color: theme.textSecondary.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 8),
          HoverSvgIcon(
            assetName: 'assets/icons/close.svg',
            width: 20,
            height: 20,
            onTap: onClose,
            color: theme.textPrimary,
          ),
        ],
      ),
    );
  }
}
