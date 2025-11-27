import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
import 'package:zilpay/state/app_state.dart';

class WalletListItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback? onTap;
  final bool disabled;

  const WalletListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  State<WalletListItem> createState() => _WalletListItemState();
}

class _WalletListItemState extends State<WalletListItem>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(duration: const Duration(milliseconds: 100), opacityEnd: 0.7);
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final opacity = widget.disabled ? 0.5 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: buildPressableWithOpacity(
        onTap: widget.onTap,
        disabled: widget.disabled,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Opacity(opacity: opacity, child: _buildIcon()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.bodyText1.copyWith(
                          color: theme.textPrimary.withValues(alpha: opacity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: theme.bodyText2.copyWith(
                          color: theme.textSecondary.withValues(alpha: opacity),
                        ),
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: opacity,
                  child: SvgPicture.asset(
                    'assets/icons/chevron_right.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (widget.icon is IconData) {
      return Icon(widget.icon as IconData);
    } else if (widget.icon is Widget) {
      return widget.icon;
    } else if (widget.icon is String) {
      return Image.asset(
        widget.icon,
        width: 24,
        height: 24,
      );
    }
    return Container();
  }
}
