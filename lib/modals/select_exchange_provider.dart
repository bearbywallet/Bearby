import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/exchange_provider_icon.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/src/rust/models/exchange.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

/// Bottom-sheet picker over the provider quotes for the current swap input. Each row shows the
/// provider's icon + name and the output it quotes (so the user sees what they trade off when
/// overriding the auto-selected best). Returns the chosen quote via [onSelected].
void showExchangeProviderSelectModal({
  required BuildContext context,
  required List<ExchangeQuoteInfo> quotes,
  required ExchangeQuoteInfo? selected,
  required FTokenInfo toToken,
  required void Function(ExchangeQuoteInfo quote) onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) => _ExchangeProviderSelectContent(
      quotes: quotes,
      selected: selected,
      toToken: toToken,
      onSelected: onSelected,
    ),
  );
}

class _ExchangeProviderSelectContent extends StatelessWidget {
  final List<ExchangeQuoteInfo> quotes;
  final ExchangeQuoteInfo? selected;
  final FTokenInfo toToken;
  final void Function(ExchangeQuoteInfo quote) onSelected;

  const _ExchangeProviderSelectContent({
    required this.quotes,
    required this.selected,
    required this.toToken,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const headerHeight = 60.0;
    const rowHeight = 64.0;
    final totalHeight = headerHeight + quotes.length * rowHeight + bottomPadding;
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      height: totalHeight.clamp(0.0, maxHeight),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: quotes.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.textSecondary.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) =>
                  _row(context, theme, appState, quotes[index]),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppTheme theme, AppState appState,
      ExchangeQuoteInfo quote) {
    final isSelected = quote == selected;
    final (outAmount, _) = formatingAmount(
      amount: BigInt.tryParse(quote.amountOut) ?? BigInt.zero,
      symbol: toToken.symbol,
      decimals: toToken.decimals,
      rate: toToken.rate,
      appState: appState,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onSelected(quote);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              exchangeProviderIconAsset(quote.provider),
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exchangeProviderName(quote.provider),
                style: theme.bodyText1.copyWith(color: theme.textPrimary),
              ),
            ),
            Text(
              outAmount,
              style: theme.bodyText1.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              isSelected
                  ? 'assets/icons/check.svg'
                  : 'assets/icons/tiny_down_arrow.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                isSelected ? theme.primaryPurple : theme.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
