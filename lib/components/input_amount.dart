import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

/// Shared token amount card: amount display, token selector and a balance row with
/// 25% / 50% / 100% chips. Presentational only — the caller supplies the [token] and
/// [balance] and reacts to [onAmountChanged] (chips) and [onTokenTap] (selector).
///
/// The amount renders at a fixed [AppTheme.displayLarge] size and scrolls
/// horizontally when it overflows, auto-scrolling to keep the newest digit visible.
class TokenAmountCard extends StatefulWidget {
  static const List<int> _percentOptions = <int>[0, 25, 50, 100];

  final String amount;
  final FTokenInfo token;
  final BigInt balance;
  final void Function(String amount) onAmountChanged;
  final VoidCallback onTokenTap;
  final bool isTokenLoading;

  const TokenAmountCard({
    super.key,
    this.amount = "0",
    required this.token,
    required this.balance,
    required this.onAmountChanged,
    required this.onTokenTap,
    this.isTokenLoading = false,
  });

  @override
  State<TokenAmountCard> createState() => _TokenAmountCardState();
}

class _TokenAmountCardState extends State<TokenAmountCard> {
  final ScrollController _amountScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(TokenAmountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount) {
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _amountScrollController.dispose();
    super.dispose();
  }

  /// After the new amount lays out, jump to the end so the newest-typed digit stays
  /// visible. Short amounts: maxScrollExtent is 0, so the value stays left-aligned.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_amountScrollController.hasClients) return;
      _amountScrollController
          .jumpTo(_amountScrollController.position.maxScrollExtent);
    });
  }

  void _setPercent(int percent) {
    final portion =
        widget.balance * BigInt.from(percent) ~/ BigInt.from(100);
    widget.onAmountChanged(
        fromWei(value: portion.toString(), decimals: widget.token.decimals));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bigAmount = toDecimalsWei(widget.amount, widget.token.decimals);

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
          _buildBalanceRow(theme, bigAmount),
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
    final effectiveRate = widget.token.rate != 0.0
        ? widget.token.rate
        : (appState.wallet?.tokens
                .where((t) => t.addr == widget.token.addr)
                .firstOrNull
                ?.rate ??
            0.0);

    final (_, converted) = formatingAmount(
      amount: bigAmount,
      symbol: widget.token.symbol,
      decimals: widget.token.decimals,
      rate: effectiveRate,
      appState: appState,
    );

    final showConverted = appState.wallet?.settings.currencyConvert != null &&
        converted.isNotEmpty &&
        converted != '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed font: never resizes. Horizontal scroll reveals overflow; the
        // ScrollController (see didUpdateWidget) keeps the newest digit visible.
        SingleChildScrollView(
          controller: _amountScrollController,
          scrollDirection: Axis.horizontal,
          child: Text(
            widget.amount,
            maxLines: 1,
            softWrap: false,
            style: theme.displayLarge.copyWith(
              color: theme.textPrimary,
              fontSize: 32.0,
            ),
          ),
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
      onTap: widget.isTokenLoading ? null : widget.onTokenTap,
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
            if (widget.isTokenLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryPurple,
                ),
              )
            else
              TokenAvatar(token: widget.token, appState: appState),
            const SizedBox(width: 8),
            Text(
              widget.token.symbol,
              style: theme.bodyText1.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            AppIconView(
              icon: AppIcon.arrowDown,
              size: 12,
              color: theme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(AppTheme theme, BigInt currentAmount) {
    final bool isExceeded = currentAmount > widget.balance;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isExceeded)
          AppIconView(
            icon: AppIcon.warning,
            size: 15,
            color: theme.warning.withValues(alpha: 0.7),
          ),
        if (isExceeded) const SizedBox(width: 4),
        Flexible(
          child: Text(
            fromWei(
                value: widget.balance.toString(),
                decimals: widget.token.decimals),
            style: theme.bodyText2.copyWith(
              color: theme.textPrimary.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        ...List<Widget>.generate(
            TokenAmountCard._percentOptions.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(width: 8);
          }

          final percent = TokenAmountCard._percentOptions[index ~/ 2];
          return _percentChip(
            theme,
            percent,
            _isPercentActive(percent, currentAmount),
            () => _setPercent(percent),
          );
        }),
      ],
    );
  }

  bool _isPercentActive(int percent, BigInt currentAmount) {
    if (percent == 0) {
      return currentAmount == BigInt.zero;
    }

    if (widget.balance == BigInt.zero) {
      return false;
    }

    final portion =
        widget.balance * BigInt.from(percent) ~/ BigInt.from(100);
    return currentAmount == portion;
  }

  Widget _percentChip(
    AppTheme theme,
    int percent,
    bool isActive,
    VoidCallback onTap,
  ) {
    final backgroundColor = isActive
        ? theme.primaryPurple.withValues(alpha: 0.22)
        : theme.textPrimary.withValues(alpha: 0.1);
    final borderColor = isActive
        ? theme.primaryPurple.withValues(alpha: 0.7)
        : Colors.transparent;
    final textColor = isActive
        ? theme.primaryPurple
        : theme.textPrimary.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$percent%',
          style: theme.labelSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
