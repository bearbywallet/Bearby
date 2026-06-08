import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/address_avatar.dart';
import 'package:bearby/components/copy_content.dart';
import 'package:bearby/components/hover_icon.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/modals/wallet_header.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/state/app_state.dart';

class WalletHeader extends StatefulWidget {
  final AccountInfo account;
  final Function()? onTap;
  final VoidCallback onSettings;
  final VoidCallback? onScan;

  const WalletHeader({
    super.key,
    required this.account,
    required this.onSettings,
    this.onTap,
    this.onScan,
  });

  @override
  State<WalletHeader> createState() => _WalletHeaderState();
}

class _WalletHeaderState extends State<WalletHeader>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(opacityEnd: 0.5);
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  void _showWalletModal() {
    showWalletModal(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final avatarSize = AdaptiveSize.getAdaptiveIconSize(context, 40);
    final gearSize = AdaptiveSize.getAdaptiveIconSize(context, 26);
    final spacing = AdaptiveSize.getAdaptiveSize(context, 8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: buildPressableWithOpacity(
                  onTap: () {
                    _showWalletModal();
                    widget.onTap?.call();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AvatarAddress(
                        avatarSize: avatarSize,
                        account: widget.account,
                      ),
                      SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          widget.account.name,
                          style: theme.headline2.copyWith(
                            color: theme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onScan != null) ...[
                    HoverIcon(
                      icon: AppIcon.scan,
                      size: gearSize,
                      padding: const EdgeInsets.all(0),
                      color: theme.textSecondary,
                      onTap: widget.onScan!,
                    ),
                    SizedBox(width: spacing),
                  ],
                  HoverIcon(
                    icon: AppIcon.gear,
                    size: gearSize,
                    padding: const EdgeInsets.all(0),
                    color: theme.textSecondary,
                    onTap: widget.onSettings,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing),
          CopyContent(
            address: widget.account.addr,
          ),
        ],
      ),
    );
  }
}
