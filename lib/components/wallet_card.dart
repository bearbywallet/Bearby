import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/address_avatar.dart';
import 'package:zilpay/mixins/addr.dart';
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
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  bool isPressed = false;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return MouseRegion(
      onEnter: (_) {
        setState(() => isHovered = true);
        _controller.forward(from: 0.5);
      },
      onExit: (_) {
        setState(() => isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => isPressed = false);
          _controller.reverse();
        },
        onTapCancel: () {
          setState(() => isPressed = false);
          _controller.reverse();
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Transform.scale(
            scale: _animation.value,
            child: child,
          ),
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
        ),
      ),
    );
  }
}
