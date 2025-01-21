import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/colors.dart';
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
    this.amount = "0",
    this.convertAmount = "0",
    this.tokenIndex = 0,
    this.showMax = true,
    required this.onMaxTap,
    required this.onTokenSelected,
  });

  @override
  State<TokenAmountCard> createState() => _TokenAmountCardState();
}

class _TokenAmountCardState extends State<TokenAmountCard> {
  Key _imageKey = UniqueKey();

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
    final balance = adjustAmountToDouble(bigBalance, token.decimals);
    final provider = appState.state.providers[token.chainHash.toInt()];

    const double amountHeight = 40.0;
    const double convertHeight = 20.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: theme.textSecondary.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: amountHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.amount,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize:
                                _calculateFontSize(context, widget.amount),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: convertHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.convertAmount,
                          style: TextStyle(
                            color: theme.textPrimary.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showTokenSelectModal(
                    context: context,
                    onTokenSelected: (int index) {
                      widget.onTokenSelected(index);
                      _imageKey = UniqueKey();
                    },
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.textPrimary.withOpacity(0.2),
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
                            color: theme.textPrimary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: AsyncImage(
                          key: _imageKey,
                          url: viewTokenIcon(
                            token,
                            provider.chainId,
                            theme.value,
                          ),
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorWidget: Blockies(
                            seed: token.addr,
                            color: getWalletColor(0),
                            bgColor: theme.primaryPurple,
                            spotColor: theme.background,
                            size: 8,
                          ),
                          loadingWidget: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        token.symbol,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
                  color: theme.textPrimary.withOpacity(0.7),
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
                      color: theme.textPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Max',
                      style: TextStyle(
                        color: theme.textPrimary.withOpacity(0.7),
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
    );
  }

  double _getAmount() {
    try {
      return double.parse(widget.amount);
    } catch (e) {
      return 0;
    }
  }

  double _calculateFontSize(BuildContext context, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseSize = 30.0;
    const minSize = 13.0;
    final charCount = text.length;

    if (charCount <= 8) {
      return baseSize;
    }

    final fontSize = (screenWidth * 0.12) / ((charCount - 8) * 0.5);

    return fontSize.clamp(minSize, baseSize);
  }
}
