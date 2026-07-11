import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/services/whitebird_orders.dart';
import 'package:bearby/src/rust/models/exchange/whitebird/orders.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

/// Finish an abandoned sell order: open the wallet transfer confirm for its
/// deposit address; return `true` once the transaction is broadcast.
typedef WhiteBirdOrderCompleter = Future<bool> Function(WhiteBirdOpenOrder order);

/// Close an order locally (no server cancel API — WhiteBird expires it on its
/// own); returns the updated open-order list.
typedef WhiteBirdOrderDismisser = Future<List<WhiteBirdOpenOrder>> Function(
    WhiteBirdOpenOrder order);

/// Cancel the order server-side (WhiteBird `client/order/{id}/reject`);
/// returns the refreshed open-order list.
typedef WhiteBirdOrderCanceller = Future<List<WhiteBirdOpenOrder>> Function(
    WhiteBirdOpenOrder order);

/// Renders a human decimal amount + WhiteBird asset code with the app's
/// standard amount formatting.
typedef WhiteBirdAmountFormatter = String Function(
    String amountHuman, String assetCode);

void showWhiteBirdOrdersModal({
  required BuildContext context,
  required List<WhiteBirdOpenOrder> orders,
  required WhiteBirdOrderCompleter onComplete,
  required WhiteBirdOrderDismisser onDismiss,
  required WhiteBirdOrderCanceller onCancel,
  required WhiteBirdAmountFormatter formatAmount,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (_) => _WhiteBirdOrdersContent(
      orders: orders,
      onComplete: onComplete,
      onDismiss: onDismiss,
      onCancel: onCancel,
      formatAmount: formatAmount,
    ),
  );
}

class _WhiteBirdOrdersContent extends StatefulWidget {
  final List<WhiteBirdOpenOrder> orders;
  final WhiteBirdOrderCompleter onComplete;
  final WhiteBirdOrderDismisser onDismiss;
  final WhiteBirdOrderCanceller onCancel;
  final WhiteBirdAmountFormatter formatAmount;

  const _WhiteBirdOrdersContent({
    required this.orders,
    required this.onComplete,
    required this.onDismiss,
    required this.onCancel,
    required this.formatAmount,
  });

  @override
  State<_WhiteBirdOrdersContent> createState() =>
      _WhiteBirdOrdersContentState();
}

class _WhiteBirdOrdersContentState extends State<_WhiteBirdOrdersContent> {
  late List<WhiteBirdOpenOrder> _orders = widget.orders;
  bool _busy = false;

  Future<void> _complete(WhiteBirdOpenOrder order) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final done = await widget.onComplete(order);
      if (done && mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(WhiteBirdOpenOrder order) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = await widget.onCancel(order);
      if (!mounted) return;
      if (next.isEmpty) {
        Navigator.pop(context);
        return;
      }
      setState(() => _orders = next);
    } catch (e) {
      debugPrint('[WhiteBirdOrders] cancel failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss(WhiteBirdOpenOrder order) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = await widget.onDismiss(order);
      if (!mounted) return;
      // Last order gone — nothing left to show.
      if (next.isEmpty) {
        Navigator.pop(context);
        return;
      }
      setState(() => _orders = next);
    } catch (e) {
      debugPrint('[WhiteBirdOrders] dismiss failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.cardBackground.withValues(alpha: 0.85),
                  theme.cardBackground.withValues(alpha: 0.95),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(theme),
                Flexible(
                  child: _orders.isEmpty
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                              24, 24, 24, 40 + bottomPadding),
                          child: Text(
                            l10n.whitebirdOrdersEmpty,
                            textAlign: TextAlign.center,
                            style: theme.bodyLarge
                                .copyWith(color: theme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(
                              24, 16, 24, 16 + bottomPadding),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildOrderCard(theme, l10n, _orders[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(AppTheme theme) => Container(
        margin: const EdgeInsets.only(top: 12),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: theme.textSecondary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  static String _shortDate(String iso) {
    final tIndex = iso.indexOf('T');
    return tIndex > 0 ? iso.substring(0, tIndex) : iso;
  }

  /// Minimal card: tap continues an awaiting-deposit order (wallet transfer
  /// confirm), the ✕ icon cancels it server-side (or locally dismisses
  /// non-actionable orders).
  Widget _buildOrderCard(
      AppTheme theme, AppLocalizations l10n, WhiteBirdOpenOrder order) {
    final needsDeposit = order.awaitingDeposit;
    final expires = order.expiresAt;
    return GestureDetector(
      onTap: needsDeposit && !_busy ? () => _complete(order) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.15), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.formatAmount(order.fromAmount, order.fromAsset)}'
                    ' → '
                    '${widget.formatAmount(order.toAmount, order.toAsset)}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyText1.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (order.number != null) '#${order.number}',
                      if (expires != null)
                        '${l10n.whitebirdOrdersExpires} ${_shortDate(expires)}',
                    ].join('  ·  '),
                    style:
                        theme.bodyText2.copyWith(color: theme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _busy
                  ? null
                  : () => needsDeposit ? _cancel(order) : _dismiss(order),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AppIconView(
                  icon: AppIcon.close,
                  size: 18,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
