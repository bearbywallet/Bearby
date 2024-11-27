import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import '../theme/theme_provider.dart';

class TokenCard extends StatefulWidget {
  final double tokenAmount;
  final double convertAmount;
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
    required this.convertAmount,
    required this.tokenName,
    required this.tokenSymbol,
    required this.tokenAddr,
    required this.iconUrl,
    this.currencySymbol = '\$',
    this.showDivider = true,
    this.onTap,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> {
  bool isHovered = false;
  bool isPressed = false;

  String formatAmount(double amount) {
    if (amount >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(2)}B';
    } else if (amount >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(2)}M';
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => isPressed = true),
            onTapUp: (_) => setState(() => isPressed = false),
            onTapCancel: () => setState(() => isPressed = false),
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: isPressed
                    ? Colors.grey.withOpacity(0.2)
                    : isHovered
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.transparent,
              ),
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
                          Row(
                            children: [
                              Text(
                                widget.tokenName,
                                style: TextStyle(
                                  color: theme.textPrimary.withOpacity(0.7),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${widget.tokenSymbol})',
                                style: TextStyle(
                                  color: theme.textSecondary.withOpacity(0.5),
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                formatAmount(widget.tokenAmount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.currencySymbol}${formatAmount(widget.convertAmount)}',
                                style: TextStyle(
                                  color: theme.textSecondary.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          widget.iconUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.primaryPurple.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Blockies(
                                  seed: widget.tokenAddr,
                                  color: getWalletColor(0),
                                  bgColor: theme.primaryPurple,
                                  spotColor: theme.background,
                                  size: 8,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
      ],
    );
  }
}
