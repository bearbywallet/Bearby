import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
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
  bool isHovered = false;
  bool isPressed = false;
  bool isExpanded = false;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(AppState appState) {
    final theme = appState.currentTheme;
    FTokenInfo token = appState.wallet!.tokens
        .firstWhere((t) => t.symbol == widget.transaction.tokenInfo?.symbol);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: ClipOval(
          child: AsyncImage(
        url: widget.transaction.icon ??
            viewTokenIcon(
              token,
              appState.chain!.chainId,
              theme.value,
            ),
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        errorWidget: Blockies(
          seed: widget.transaction.id,
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
      )),
    );
  }

  Widget _buildTransactionDetails(AppState appState) {
    final theme = appState.currentTheme;
    final nativeToken = appState.wallet!.tokens.first;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isExpanded ? null : 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              theme,
              'hash:',
              "0x${widget.transaction.id}",
              true,
            ),
            _buildDetailRow(
              theme,
              'From:',
              widget.transaction.sender,
              true,
            ),
            _buildDetailRow(
              theme,
              'To:',
              widget.transaction.recipient,
              true,
            ),
            if (widget.transaction.teg != null)
              _buildDetailRow(
                theme,
                'Tag:',
                widget.transaction.teg!,
                false,
              ),
            _buildDetailRow(
              theme,
              'Nonce:',
              widget.transaction.nonce.toString(),
              false,
            ),
            _buildDetailRow(
              theme,
              'Fee:',
              '${(adjustAmountToDouble(widget.transaction.fee, nativeToken.decimals))} ${appState.chain!.chain}',
              false,
            ),
            if (widget.transaction.confirmed != null)
              _buildDetailRow(
                theme,
                'Block:',
                widget.transaction.confirmed.toString(),
                false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    AppTheme theme,
    String label,
    String value,
    bool isCopyable,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            child: Text(
              label,
              style: TextStyle(
                color: theme.textSecondary.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: theme.textSecondary.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: value)),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SvgPicture.asset(
                        "assets/icons/copy.svg",
                        width: 30,
                        height: 30,
                        colorFilter: ColorFilter.mode(
                          theme.textSecondary.withValues(alpha: 0.4),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
      widget.transaction.timestamp.toInt() * 1000,
    );
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  String _formatAmount() {
    if (widget.transaction.tokenInfo != null) {
      final decimals = widget.transaction.tokenInfo!.decimals;
      final value = BigInt.parse(
          widget.transaction.tokenInfo?.value ?? widget.transaction.amount);
      final formattedValue = adjustAmountToDouble(value, decimals);

      return '${formatCompactNumber(formattedValue)} ${widget.transaction.tokenInfo!.symbol}';
    }
    return widget.transaction.amount;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) {
            setState(() => isHovered = true);
            _controller.forward(from: 0.5);
          },
          onExit: (_) {
            setState(() => isHovered = false);
            _controller.reverse();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              setState(() => isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() {
                isPressed = false;
                isExpanded = !isExpanded;
              });
              _controller.reverse();
            },
            onTapCancel: () {
              setState(() => isPressed = false);
              _controller.reverse();
            },
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Transform.scale(
                scale: _animation.value,
                child: child,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isHovered || isExpanded
                      ? theme.textPrimary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: adaptivePadding,
                        vertical: adaptivePadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(theme)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.transaction.status.name
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(theme),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _formatAmount(),
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    _buildIcon(Provider.of<AppState>(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: adaptivePadding,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _formatDateTime(),
                                style: TextStyle(
                                  color: theme.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        )),
                    _buildTransactionDetails(state),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            height: 1,
            color: theme.textPrimary.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}
