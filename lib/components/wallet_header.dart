import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
import 'package:zilpay/modals/wallet_header.dart';
import 'package:zilpay/src/rust/models/account.dart';
import 'package:zilpay/state/app_state.dart';

class WalletHeader extends StatefulWidget {
  final AccountInfo account;
  final Function()? onTap;
  final VoidCallback onSettings;

  const WalletHeader({
    super.key,
    required this.account,
    required this.onSettings,
    this.onTap,
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
    showWalletModal(
      context: context,
      onManageWallet: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final avatarSize = AdaptiveSize.getAdaptiveIconSize(context, 50);
    final gearSize = AdaptiveSize.getAdaptiveIconSize(context, 32);
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
              buildPressableWithOpacity(
                onTap: () {
                  _showWalletModal();
                  widget.onTap?.call();
                },
                child: AvatarAddress(
                  avatarSize: avatarSize,
                  account: widget.account,
                ),
              ),
              HoverSvgIcon(
                assetName: 'assets/icons/gear.svg',
                width: gearSize,
                height: gearSize,
                padding: EdgeInsets.fromLTRB(spacing * 2, 0, 0, 0),
                color: theme.textSecondary,
                onTap: widget.onSettings,
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.account.name,
                style: theme.headline2.copyWith(
                  color: theme.textPrimary,
                  fontSize: theme.headline2.fontSize,
                ),
              ),
              SizedBox(width: spacing),
              CopyContent(
                address: widget.account.addr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
