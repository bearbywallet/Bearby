import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import '../theme/theme_provider.dart';

class TokenCard extends StatelessWidget {
  final double tokenAmount;
  final double convertAmount;
  final String tokenName;
  final String tokenSymbol;
  final String iconUrl;
  final String currencySymbol;
  final bool showDivider;

  const TokenCard({
    super.key,
    required this.tokenAmount,
    required this.convertAmount,
    required this.tokenName,
    required this.tokenSymbol,
    required this.iconUrl,
    this.currencySymbol = '\$',
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: adaptivePadding, vertical: adaptivePadding),
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
                          tokenName,
                          style: TextStyle(
                            color: theme.textPrimary.withOpacity(0.7),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($tokenSymbol)',
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
                          tokenAmount.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$currencySymbol${convertAmount.toStringAsFixed(2)}',
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
                child: Image.network(
                  iconUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
      ],
    );
  }
}
