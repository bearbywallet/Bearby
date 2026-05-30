import 'package:bearby/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

/// Shared token amount card: amount display, token selector and a balance row with
/// 25% / 50% / 100% chips. Presentational only — the caller supplies the [token] and
/// [balance] and reacts to [onAmountChanged] (chips) and [onTokenTap] (selector).
class TokenAmountCard extends StatelessWidget {
  final String amount;
  final FTokenInfo token;
  final BigInt balance;
  final void Function(String amount) onAmountChanged;
  final VoidCallback onTokenTap;

  const TokenAmountCard({
    super.key,
    this.amount = "0",
    required this.token,
    required this.balance,
    required this.onAmountChanged,
    required this.onTokenTap,
  });

  void _setPercent(int percent) {
    final portion = balance * BigInt.from(percent) ~/ BigInt.from(100);
    onAmountChanged(fromWei(value: portion.toString(), decimals: token.decimals));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bigAmount = toDecimalsWei(amount, token.decimals);

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
          _buildAmountRow(context, theme, bigAmount, appState),
          const SizedBox(height: 8),
          _buildBalanceRow(theme),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    AppTheme theme,
    BigInt bigAmount,
    AppState appState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildAmountInfo(context, theme, bigAmount, appState),
        ),
        _buildTokenSelector(appState, theme),
      ],
    );
  }

  Widget _buildAmountInfo(
    BuildContext context,
    AppTheme theme,
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

    final fontSize = _calculateAdaptiveFontSize(context, amount);
    final showConverted = appState.wallet?.settings.currencyConvert != null &&
        converted.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: theme.displayLarge.copyWith(
            color: theme.textPrimary,
            fontSize: fontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showConverted)
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

  Widget _buildTokenSelector(AppState appState, AppTheme theme) {
    return GestureDetector(
      onTap: onTokenTap,
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
            _buildTokenIcon(appState, theme),
            const SizedBox(width: 8),
            Text(
              token.symbol,
              style: theme.bodyText1.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              "assets/icons/tiny_down_arrow.svg",
              width: 12,
              height: 12,
              colorFilter:
                  ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenIcon(AppState appState, AppTheme theme) {
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
          key: ValueKey(token.addr),
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
      ),
    );
  }

  Widget _buildBalanceRow(AppTheme theme) {
    final currentAmount = toDecimalsWei(amount, token.decimals);
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
        Flexible(
          child: Text(
            fromWei(value: balance.toString(), decimals: token.decimals),
            style: theme.bodyText2.copyWith(
              color: theme.textPrimary.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        _percentChip(theme, '0%', () => _setPercent(0)),
        const SizedBox(width: 8),
        _percentChip(theme, '25%', () => _setPercent(25)),
        const SizedBox(width: 8),
        _percentChip(theme, '50%', () => _setPercent(50)),
        const SizedBox(width: 8),
        _percentChip(theme, '100%', () => _setPercent(100)),
      ],
    );
  }

  Widget _percentChip(AppTheme theme, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.textPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.labelSmall.copyWith(
            color: theme.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ),
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
