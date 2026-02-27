import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';

class NetworkDownButton extends StatefulWidget {
  final VoidCallback onPressed;
  final NetworkConfigInfo chain;

  const NetworkDownButton({
    super.key,
    required this.onPressed,
    required this.chain,
  });

  @override
  NetworkDownButtonState createState() => NetworkDownButtonState();
}

class NetworkDownButtonState extends State<NetworkDownButton>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;

    return buildPressable(
      onTap: widget.onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.textSecondary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AsyncImage(
                  url: viewChain(network: widget.chain, theme: theme.value),
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                if (widget.chain.testnet == true) ...[
                  const SizedBox(width: 6),
                  Text(
                    'testnet',
                    style: theme.labelSmall.copyWith(color: theme.warning),
                  ),
                ],
                const SizedBox(width: 6),
                SvgPicture.asset(
                  "assets/icons/tiny_down_arrow.svg",
                  width: 10,
                  height: 10,
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
