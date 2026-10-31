import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/address_avatar.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class WalletCard extends StatefulWidget {
  final AccountInfo account;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final double? width;
  final double? height;
  final double? fontSize;
  final double avatarSize;

  const WalletCard({
    super.key,
    required this.account,
    required this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.width,
    this.height,
    this.fontSize,
    this.avatarSize = 42,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  late BigInt _balanceKey;
  bool _isCopied = false;
  Timer? _copyTimer;

  @override
  void initState() {
    super.initState();
    initPressAnimation();
    _balanceKey = addressToHash(addr: widget.account.addr);
  }

  @override
  void didUpdateWidget(covariant WalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.addr != widget.account.addr) {
      _balanceKey = addressToHash(addr: widget.account.addr);
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    disposePressAnimation();
    super.dispose();
  }

  void _copyAddress() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.account.addr));
    _copyTimer?.cancel();
    setState(() => _isCopied = true);
    _copyTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final isSelected = widget.isSelected;

    final nonZeroTokens = <FTokenInfo>[];
    for (final t in state.wallet?.tokens ?? const <FTokenInfo>[]) {
      if (t.addrType == widget.account.addrType) {
        final raw =
            BigInt.tryParse(t.balances[_balanceKey] ?? '0') ?? BigInt.zero;
        if (raw > BigInt.zero) {
          nonZeroTokens.add(t);
        }
      }
    }

    return buildPressable(
      onTap: widget.onTap,
      enableHover: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: widget.width ?? double.infinity,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    theme.primaryPurple.withValues(alpha: 0.16),
                    theme.primaryPurple.withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : theme.textSecondary.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected
                ? theme.primaryPurple.withValues(alpha: 0.75)
                : theme.textSecondary.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.primaryPurple
                      : theme.textSecondary.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.account.name,
                          style: theme.bodyLarge.copyWith(
                            color: theme.textPrimary,
                            fontSize: widget.fontSize ?? 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#${widget.account.index}',
                        style: theme.labelSmall.copyWith(
                          color: isSelected
                              ? theme.primaryPurple
                              : theme.textSecondary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _copyAddress,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            shortenAddress(widget.account.addr),
                            style: theme.bodyText2.copyWith(
                              color: _isCopied
                                  ? theme.success
                                  : theme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: AppIconView(
                            key: ValueKey<bool>(_isCopied),
                            icon: _isCopied ? AppIcon.check : AppIcon.copy,
                            size: 13,
                            color: _isCopied
                                ? theme.success
                                : theme.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (nonZeroTokens.isNotEmpty) ...[
              const SizedBox(width: 8),
              _TokenIconStack(
                tokens: nonZeroTokens,
                theme: theme,
                appState: state,
              ),
            ],
            if (widget.onDelete != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onDelete?.call();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.danger.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AppIconView(
                    icon: AppIcon.minus,
                    size: 16,
                    color: theme.danger,
                  ),
                ),
              ),
            ],
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
  final AppTheme theme;
  final AppState appState;

  const _TokenIconStack({
    required this.tokens,
    required this.theme,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final visible = tokens.take(5).toList();
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
    return TokenAvatar(
      token: token,
      size: _iconSize,
      appState: appState,
      showNetworkBadge: false,
      borderColor: theme.cardBackground,
      borderWidth: 1.5,
      fit: BoxFit.contain,
      errorWidget: const SizedBox.shrink(),
      loadingWidget: const SizedBox.shrink(),
    );
  }
}
