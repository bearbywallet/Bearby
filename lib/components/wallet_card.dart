import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/address_avatar.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

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
    this.avatarSize = 44,
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

    final balanceKey = addressToHash(addr: widget.account.addr);
    final nonZeroTokens = (state.wallet?.tokens ?? [])
        .where((t) => t.addrType == widget.account.addrType)
        .where((t) {
          final raw =
              BigInt.tryParse(t.balances[balanceKey] ?? '0') ?? BigInt.zero;
          return raw > BigInt.zero;
        })
        .toList();

    return buildPressable(
      onTap: widget.onTap,
      enableHover: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: widget.isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryPurple.withValues(alpha: 0.13),
                    theme.cardBackground.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: widget.isSelected ? null : const Color(0x00000000),
          border: Border.all(
            color: widget.isSelected
                ? theme.primaryPurple.withValues(alpha: 0.28)
                : const Color(0x00000000),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarAddress(
              avatarSize: widget.avatarSize,
              account: widget.account,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.account.name,
                    style: theme.bodyText1.copyWith(
                      color: theme.textPrimary,
                      fontSize: widget.fontSize ?? 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortenAddress(widget.account.addr,
                        leftSize: 8, rightSize: 8),
                    style: theme.caption.copyWith(
                      color: theme.textSecondary,
                      fontSize: (widget.fontSize ?? 15) - 3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nonZeroTokens.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _TokenIconStack(
                      tokens: nonZeroTokens,
                      shortName: state.chain?.shortName ?? '',
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenIconStack extends StatelessWidget {
  static const double _iconSize = 20;
  static const double _overlap = 14;

  final List<FTokenInfo> tokens;
  final String shortName;
  final AppTheme theme;

  const _TokenIconStack({
    required this.tokens,
    required this.shortName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final visible = tokens.take(6).toList();
    final totalWidth = _iconSize + (visible.length - 1) * _overlap;

    return SizedBox(
      width: totalWidth,
      height: _iconSize,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * _overlap,
              child: _buildIcon(visible[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(FTokenInfo token) {
    final url = processTokenLogo(
      token: token,
      shortName: shortName,
      theme: theme.value,
    );

    return Container(
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.cardBackground,
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: url,
          width: _iconSize,
          height: _iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
