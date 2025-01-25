import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/state/app_state.dart';

class TokenCard extends StatefulWidget {
  final String tokenAmount;
  final int tokenDecimals;
  final String tokenName;
  final String tokenSymbol;
  final String tokenAddr;
  final String iconUrl;
  final String currencySymbol;
  final bool showDivider;
  final VoidCallback? onTap;

  const TokenCard({
    super.key,
    required this.tokenAmount,
    required this.tokenDecimals,
    required this.tokenName,
    required this.tokenSymbol,
    required this.tokenAddr,
    required this.iconUrl,
    required this.currencySymbol,
    this.showDivider = true,
    this.onTap,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard>
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

  Widget _buildIcon(AppState themeProvider) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              themeProvider.currentTheme.primaryPurple.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: widget.iconUrl,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorWidget: Blockies(
            seed: widget.tokenAddr,
            color: getWalletColor(0),
            bgColor: themeProvider.currentTheme.primaryPurple,
            spotColor: themeProvider.currentTheme.background,
            size: 8,
          ),
          loadingWidget: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final double tokenAmount = _getAmount();
    final convertedAmount = getConvertedAmount(state, tokenAmount);
    final String amount = formatCompactNumber(tokenAmount);

    return Column(
      children: [
        MouseRegion(
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
                decoration: const BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptivePadding,
                    vertical: adaptivePadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.tokenName,
                                        style: TextStyle(
                                          color: theme.textPrimary
                                              .withValues(alpha: 0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${widget.tokenSymbol})',
                                      style: TextStyle(
                                        color: theme.textSecondary
                                            .withValues(alpha: 0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    amount,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$convertedAmount${widget.currencySymbol}',
                                  style: TextStyle(
                                    color: theme.textSecondary
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: _buildIcon(Provider.of<AppState>(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            height: 1,
            color: theme.textPrimary.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  double _getAmount() {
    try {
      BigInt value = BigInt.parse(widget.tokenAmount);
      return adjustAmountToDouble(value, widget.tokenDecimals);
    } catch (_) {
      return 0;
    }
  }
}
