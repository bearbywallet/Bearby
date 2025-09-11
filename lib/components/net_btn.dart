import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(20.0),
            border:
                Border.all(color: theme.textSecondary.withValues(alpha: 0.4)),
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
      ),
    );
  }
}
