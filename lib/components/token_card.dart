import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:http/http.dart' as http;
import 'package:zilpay/state/app_state.dart';

// TODO: make a cache image loading! remove http
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
  String? contentType;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkImageType();
  }

  Future<void> _checkImageType() async {
    setState(() => isLoading = true);
    try {
      final response = await http.head(Uri.parse(widget.iconUrl));
      if (mounted) {
        setState(() {
          contentType = response.headers['content-type'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          contentType = null;
          isLoading = false;
        });
      }
    }
  }

  Widget _buildIcon(AppState themeProvider) {
    if (isLoading) {
      return SizedBox(
        width: 25,
        height: 25,
      );
    }

    if (contentType?.contains('svg') ?? false) {
      return SvgPicture.network(
        widget.iconUrl,
        width: 32,
        height: 32,
        placeholderBuilder: (context) => SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Image.network(
      widget.iconUrl,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      headers: const {
        'Accept': 'image/jpeg,image/png,image/svg+xml,image/*,*/*;q=0.8',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
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
              color: themeProvider.currentTheme.primaryPurple.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Blockies(
              seed: widget.tokenAddr,
              color: getWalletColor(0),
              bgColor: themeProvider.currentTheme.primaryPurple,
              spotColor: themeProvider.currentTheme.background,
              size: 8,
            ),
          ),
        );
      },
    );
  }

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
    final theme = Provider.of<AppState>(context).currentTheme;
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
                        child: _buildIcon(Provider.of<AppState>(context)),
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
