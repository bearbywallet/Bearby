import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blockies/blockies.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class HistoryItem extends StatefulWidget {
  final HistoricalTransactionInfo transaction;
  final bool showDivider;
  final VoidCallback? onTap;

  const HistoryItem({
    super.key,
    required this.transaction,
    this.showDivider = true,
    this.onTap,
  });

  @override
  State<HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<HistoryItem>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _animation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(AppState appState) {
    final theme = appState.currentTheme;
    if (appState.wallet == null || appState.account == null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: theme.primaryPurple.withValues(alpha: 0.1), width: 2)),
        child: ClipOval(
          child: Blockies(
              seed: widget.transaction.transactionHash,
              color: theme.secondaryPurple,
              bgColor: theme.primaryPurple,
              spotColor: theme.background,
              size: 8),
        ),
      );
    }
    final token = appState.wallet!.tokens.firstWhere(
      (t) =>
          t.symbol == widget.transaction.tokenInfo?.symbol &&
          t.addrType == appState.account?.addrType,
      orElse: () => FTokenInfo(
        name: '',
        symbol: widget.transaction.tokenInfo?.symbol ?? '',
        decimals: widget.transaction.tokenInfo?.decimals ??
            appState.wallet!.tokens.first.decimals,
        addr: '',
        addrType: appState.wallet!.tokens.first.addrType,
        balances: {},
        default_: false,
        native: false,
        chainHash: BigInt.zero,
      ),
    );
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: theme.primaryPurple.withValues(alpha: 0.1), width: 2)),
      child: ClipOval(
        child: AsyncImage(
          url: widget.transaction.icon ?? processTokenLogo(token, theme.value),
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorWidget: Blockies(
              seed: widget.transaction.transactionHash,
              color: theme.secondaryPurple,
              bgColor: theme.primaryPurple,
              spotColor: theme.background,
              size: 8),
          loadingWidget:
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  Color _getStatusColor(AppTheme theme) {
    switch (widget.transaction.status) {
      case TransactionStatusInfo.confirmed:
        return theme.success;
      case TransactionStatusInfo.pending:
        return theme.warning;
      case TransactionStatusInfo.rejected:
        return theme.danger;
    }
  }

  String _formatDateTime() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
        widget.transaction.timestamp.toInt() * 1000);
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  Widget _buildAmountWithPrice(AppTheme theme) {
    if (widget.transaction.tokenInfo != null) {
      final formatter = NumberFormat('#,##0.##################');
      final decimals = widget.transaction.tokenInfo!.decimals;
      final value = double.parse(widget.transaction.tokenInfo?.value ??
              widget.transaction.amount) /
          BigInt.from(10).pow(decimals).toDouble();
      final formattedValue = formatter.format(value);
      final price = 0.004;
      final usdAmount = value * price;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$formattedValue ${widget.transaction.tokenInfo!.symbol}',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('(\$$usdAmount)',
              style: TextStyle(
                  color: theme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400)),
        ],
      );
    }
    return Text(widget.transaction.amount,
        style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
        overflow: TextOverflow.ellipsis);
  }

  Widget _buildFeeWithPrice(AppState appState) {
    final formatter = NumberFormat('#,##0.##################');
    formatter.maximumFractionDigits = 10;

    final theme = appState.currentTheme;
    final token = appState.wallet!.tokens.first;
    final decimals =
        widget.transaction.chainType == "EVM" && token.decimals < 18
            ? 18
            : token.decimals;
    final feeBig = widget.transaction.fee.toDouble();
    final price = 0;
    final value = feeBig / BigInt.from(10).pow(decimals).toDouble();
    final fee = formatter.format(value);
    final usdFee = value * price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$fee ${token.symbol}',
            style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('(\$$usdFee)',
            style: TextStyle(
                color: theme.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w400)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    return Column(
      children: [
        MouseRegion(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              setState(() => isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() => isPressed = false);
              _controller.reverse();
            },
            onTapCancel: () {
              setState(() => isPressed = false);
              _controller.reverse();
            },
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) =>
                  Transform.scale(scale: _animation.value, child: child),
              child: Padding(
                padding: EdgeInsets.all(adaptivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: _getStatusColor(theme)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text(
                                        widget.transaction.status.name
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: _getStatusColor(theme),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                        widget.transaction.title ??
                                            'Transaction',
                                        style: TextStyle(
                                            color: theme.textPrimary
                                                .withValues(alpha: 0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildAmountWithPrice(theme),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildIcon(state),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDateTime(),
                            style: TextStyle(
                                color:
                                    theme.textSecondary.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w400)),
                        _buildFeeWithPrice(state),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Container(height: 1, color: theme.textPrimary.withValues(alpha: 0.1)),
      ],
    );
  }
}
