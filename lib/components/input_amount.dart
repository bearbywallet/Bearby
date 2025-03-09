import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/select_token.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class TokenAmountCard extends StatefulWidget {
  final String amount;
  final int tokenIndex;
  final bool showMax;
  final Function(String) onMaxTap;
  final Function(int) onTokenSelected;

  const TokenAmountCard({
    super.key,
    this.amount = "0",
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
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final token = appState.wallet!.tokens[widget.tokenIndex];
    final BigInt bigAmount = toWei(widget.amount, token.decimals);
    final bigBalance =
        BigInt.parse(token.balances[appState.wallet!.selectedAccount] ?? '0');
    final double balance = adjustAmountToDouble(bigBalance, token.decimals);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildAmountRow(context, theme, token, bigAmount, appState),
          const SizedBox(height: 8),
          _buildBalanceRow(theme, balance),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    AppTheme theme,
    FTokenInfo token,
    BigInt bigAmount,
    AppState appState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildAmountInfo(context, theme, token, bigAmount, appState),
        ),
        _buildTokenSelector(context, theme, token),
      ],
    );
  }

  Widget _buildAmountInfo(
    BuildContext context,
    AppTheme theme,
    FTokenInfo token,
    BigInt bigAmount,
    AppState appState,
  ) {
    const double amountHeight = 40.0;
    const double convertHeight = 20.0;

    return Column(
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
                fontSize: _calculateFontSize(context, widget.amount),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (appState.wallet?.settings.currencyConvert != null)
          SizedBox(
            height: convertHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                formatingAmount(
                  amount: bigAmount,
                  symbol: token.symbol,
                  decimals: token.decimals,
                  rate: token.rate,
                  appState: appState,
                ).$2,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTokenSelector(
      BuildContext context, AppTheme theme, FTokenInfo token) {
    return GestureDetector(
      onTap: () {
        showTokenSelectModal(
          context: context,
          onTokenSelected: (int index) {
            widget.onTokenSelected(index);
            setState(() {
              _imageKey = UniqueKey();
            });
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTokenIcon(theme, token),
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
    );
  }

  Widget _buildTokenIcon(AppTheme theme, FTokenInfo token) {
    return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: AsyncImage(
            key: _imageKey,
            url: processTokenLogo(token, theme.value),
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorWidget: Blockies(
              seed: token.addr,
              color: theme.secondaryPurple,
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
        ));
  }

  Widget _buildBalanceRow(AppTheme theme, double balance) {
    final double currentAmount = _getAmount();
    final bool isExceeded = currentAmount > balance;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isExceeded)
          SvgPicture.asset(
            "assets/icons/warning.svg",
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              theme.warning.withValues(alpha: 0.7),
              BlendMode.srcIn,
            ),
          ),
        if (isExceeded) const SizedBox(width: 4),
        Text(
          balance.toString(),
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        if (widget.showMax)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => widget.onMaxTap(balance.toString()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Max',
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _getAmount() {
    try {
      return double.parse(widget.amount);
    } catch (_) {
      return 0;
    }
  }

  double _calculateFontSize(BuildContext context, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseSize = 30.0;
    const minSize = 13.0;

    if (text.length <= 8) return baseSize;

    final fontSize = (screenWidth * 0.12) / ((text.length - 8) * 0.5);
    return fontSize.clamp(minSize, baseSize);
  }
}
