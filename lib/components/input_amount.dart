import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/modals/select_token.dart';
import 'package:zilpay/state/app_state.dart';

class TokenAmountCard extends StatefulWidget {
  final String amount;
  final String convertAmount;
  final int tokenIndex;
  final bool showMax;
  final Function(String) onMaxTap;
  final Function(int) onTokenSelected;

  const TokenAmountCard({
    super.key,
    this.amount = "1",
    this.convertAmount = "3,667.88",
    this.tokenIndex = 0,
    this.showMax = true,
    required this.onMaxTap,
    required this.onTokenSelected,
  });

  @override
  State<TokenAmountCard> createState() => _TokenAmountCardState();
}

class _TokenAmountCardState extends State<TokenAmountCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final token = appState.wallet!.tokens[widget.tokenIndex];
    final bigBalance =
        BigInt.parse(token.balances[appState.wallet!.selectedAccount] ?? '0');
    final balance = adjustBalanceToDouble(bigBalance, token.decimals);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: theme.textSecondary.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.convertAmount,
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
              GestureDetector(
                onTap: () {
                  showTokenSelectModal(
                    context: context,
                    onTokenSelected: widget.onTokenSelected,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
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
                        child: SvgPicture.network(
                          viewIcon(token.addr, "Dark"),
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          placeholderBuilder: (context) => Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: theme.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30 / 2),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 / 2,
                                height: 30 / 2,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.textSecondary.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        token.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_getAmount() > balance)
                    SvgPicture.asset(
                      "assets/icons/warning.svg",
                      width: 15,
                      height: 15,
                      colorFilter: ColorFilter.mode(
                        theme.warning.withOpacity(0.7),
                        BlendMode.srcIn,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    balance.toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (widget.showMax) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onMaxTap(balance.toString()),
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

  double _getAmount() {
    try {
      return double.parse(widget.amount);
    } catch (e) {
      return 0;
    }
  }
}
