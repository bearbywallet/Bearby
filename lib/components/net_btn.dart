import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';

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
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: theme.textSecondary.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AsyncImage(
              url: viewChain(network: widget.chain, theme: theme.value),
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              loadingWidget: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
            if (widget.chain.testnet == true) ...[
              const SizedBox(width: 8),
              Text(
                'testnet',
                style: TextStyle(color: theme.warning),
              ),
            ],
            const SizedBox(width: 8),
            SvgPicture.asset(
              "assets/icons/tiny_down_arrow.svg",
              width: 8,
              height: 8,
              colorFilter: ColorFilter.mode(
                theme.textPrimary.withValues(alpha: 0.6),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
