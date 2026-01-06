import 'package:zilpay/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/select_token.dart';
import 'package:zilpay/src/rust/api/utils.dart';
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
    final bigAmount = toDecimalsWei(widget.amount.toString(), token.decimals);
    final bigBalance =
        BigInt.parse(token.balances[appState.wallet!.selectedAccount] ?? '0');

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
          _buildBalanceRow(theme, bigBalance, token),
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
        _buildTokenSelector(context, appState, token),
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
    final (_, converted) = formatingAmount(
      amount: bigAmount,
      symbol: token.symbol,
      decimals: token.decimals,
      rate: token.rate,
      appState: appState,
    );

    final fontSize = _calculateAdaptiveFontSize(context, widget.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.amount,
          style: theme.displayLarge.copyWith(
            color: theme.textPrimary,
            fontSize: fontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (appState.wallet?.settings.currencyConvert != null &&
            converted.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              converted,
              style: theme.bodyText2.copyWith(
                color: theme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildTokenSelector(
    BuildContext context,
    AppState appState,
    FTokenInfo token,
  ) {
    final theme = appState.currentTheme;

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
            _buildTokenIcon(appState, token),
            const SizedBox(width: 8),
            Text(
              token.symbol,
              style: theme.bodyText1.copyWith(
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenIcon(AppState appState, FTokenInfo token) {
    final theme = appState.currentTheme;

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
            url: processTokenLogo(
              token: token,
              shortName: appState.chain?.shortName ?? "",
              theme: theme.value,
            ),
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorWidget: Jazzicon(
              seed: token.addr,
              diameter: 24,
            ),
            loadingWidget: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        ));
  }

  Widget _buildBalanceRow(AppTheme theme, BigInt balance, FTokenInfo token) {
    final currentAmount = toDecimalsWei(widget.amount, token.decimals);
    final bool isExceeded = currentAmount > balance;
    final bool isMax = currentAmount == balance;

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
          fromWei(value: balance.toString(), decimals: token.decimals),
          style: theme.bodyText2.copyWith(
            color: theme.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        if (widget.showMax)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => widget.onMaxTap(
                  fromWei(value: balance.toString(), decimals: token.decimals)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isMax
                      ? theme.warning.withValues(alpha: 0.2)
                      : theme.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Max',
                  style: theme.labelSmall.copyWith(
                    color: isMax
                        ? theme.warning
                        : theme.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _calculateAdaptiveFontSize(BuildContext context, String text) {
    const baseSize = 32.0;
    const minSize = 16.0;

    if (text.length <= 8) {
      return AdaptiveSize.getAdaptiveFontSize(context, baseSize);
    }

    final scaleFactor = 1 - ((text.length - 8) * 0.08);
    final adjustedSize = (baseSize * scaleFactor).clamp(minSize, baseSize);

    return AdaptiveSize.getAdaptiveFontSize(context, adjustedSize);
  }
}
