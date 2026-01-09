import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
import 'package:zilpay/src/rust/models/account.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/mixins/adaptive_size.dart';

class WalletCard extends StatefulWidget {
  final AccountInfo account;
  final VoidCallback onTap;
  final bool isSelected;
  final double? width;
  final double? height;
  final double? fontSize;
  final double avatarSize;

  const WalletCard({
    super.key,
    required this.account,
    required this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
    this.fontSize,
    this.avatarSize = 50,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return buildPressable(
      onTap: widget.onTap,
      enableHover: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isSelected
              ? theme.primaryPurple.withValues(alpha: 0.1)
              : const Color(0x00000000),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: adaptivePadding,
            vertical: 4,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.textPrimary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: AvatarAddress(
                  avatarSize: widget.avatarSize,
                  account: widget.account,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.account.name,
                      style: theme.bodyText1.copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.7),
                        fontSize: widget.fontSize ?? 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortenAddress(widget.account.addr,
                          leftSize: 8, rightSize: 8),
                      style: theme.bodyText2.copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.5),
                        fontSize: (widget.fontSize ?? 16) - 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
