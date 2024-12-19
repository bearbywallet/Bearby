import 'package:flutter/material.dart';

class TokenAmountCard extends StatelessWidget {
  final String amount;
  final String dollarAmount;
  final String tokenSymbol;
  final String balanceAmount;
  final bool showMax;
  final VoidCallback? onMaxTap;

  const TokenAmountCard({
    super.key,
    this.amount = "1",
    this.dollarAmount = "\$3,667.88",
    this.tokenSymbol = "ETH",
    this.balanceAmount = "0",
    this.showMax = true,
    this.onMaxTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                dollarAmount,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  // color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.currency_exchange,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tokenSymbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.amber.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$balanceAmount $tokenSymbol",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (showMax) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onMaxTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Max',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
