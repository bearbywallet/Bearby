import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/history_amount.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/mixins/transaction_token.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

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
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  HistoryAmountView? _view;
  String _formattedDate = '';

  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recompute();
  }

  @override
  void didUpdateWidget(covariant HistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recompute();
  }

  /// Keeps `build()` free of amount/token resolution: recomputed only when
  /// the widget or its inherited dependencies change.
  void _recompute() {
    final state = Provider.of<AppState>(context, listen: false);
    _view = resolveHistoryAmount(
      transaction: widget.transaction,
      appState: state,
    );
    _formattedDate = _formatDateTime();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  Widget _buildIcon(AppState appState) {
    final theme = appState.currentTheme;
    final token = resolveTransactionIconToken(
      transaction: widget.transaction,
      appState: appState,
    );
    final icon = widget.transaction.icon;

    // Local asset SVG (e.g. "assets/icons/uniswap.svg") — render directly.
    if (icon != null && icon.startsWith('assets/') && icon.endsWith('.svg')) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: theme.primaryPurple.withValues(alpha: 0.1), width: 2)),
        child: ClipOval(
          child: SvgPicture.asset(
            icon,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Remote URL or token logo fallback — use TokenAvatar.
    return TokenAvatar(
      token: token,
      size: 32,
      appState: appState,
      showNetworkBadge: false,
      iconUrl: icon,
      borderColor: theme.primaryPurple.withValues(alpha: 0.1),
      borderWidth: 2,
      fit: BoxFit.contain,
    );
  }

  Color _getStatusColor(AppTheme theme) {
    switch (widget.transaction.status) {
      case TransactionStatusInfo.success:
        return theme.success;
      case TransactionStatusInfo.pending:
        return theme.warning;
      case TransactionStatusInfo.failed:
        return theme.danger;
    }
  }

  String _formatDateTime() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      widget.transaction.timestamp.toInt() * 1000,
    );

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _flowLabel(AppLocalizations l10n, TxFlow flow) {
    return switch (flow) {
      TxFlow.incoming => l10n.historyItemReceived,
      TxFlow.outgoing => l10n.historyItemSent,
      TxFlow.neutral => l10n.transactionDetailsModal_transaction,
    };
  }

  Widget _buildTitle(
    AppTheme theme,
    AppLocalizations l10n,
    HistoryAmountView view,
  ) {
    final title = widget.transaction.title ?? _flowLabel(l10n, view.flow);

    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: theme.bodyText1.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (view.status != TransactionStatusInfo.success) ...[
          const SizedBox(width: 6),
          Text(
            '· ${widget.transaction.status.name.toUpperCase()}',
            style: theme.caption.copyWith(
              color: _getStatusColor(theme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSignedMessageContent(AppState appState) {
    final theme = appState.currentTheme;
    final signedMsg = widget.transaction.parsedSignedMessage;
    if (signedMsg == null) {
      return const SizedBox.shrink();
    }

    String displayContent;
    if (signedMsg.isTypedData) {
      final domainName = signedMsg.domainName ?? '';
      final primaryType = signedMsg.primaryType ?? '';
      displayContent =
          domainName.isNotEmpty ? '$domainName - $primaryType' : primaryType;
    } else {
      final decoded = signedMsg.decodedMessage;
      displayContent =
          decoded.length > 50 ? '${decoded.substring(0, 50)}...' : decoded;
    }

    return Text(
      displayContent.isNotEmpty ? displayContent : 'Signed Message',
      style: theme.bodyText1.copyWith(
        color: theme.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  Widget _buildFeeWithPrice(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;

    if (widget.transaction.isSignedMessage) {
      final signedMsg = widget.transaction.parsedSignedMessage;
      if (signedMsg == null) {
        return const SizedBox.shrink();
      }

      String badgeText;
      if (signedMsg.isPersonalSign) {
        badgeText = l10n.signedMessageTypePersonalSign;
      } else if (signedMsg.isTypedData) {
        badgeText = l10n.signedMessageTypeEip712;
      } else {
        badgeText = l10n.signedMessageTypeUnknown;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          badgeText,
          style: theme.caption.copyWith(
            color: theme.primaryPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final tokens = appState.wallet?.tokens;
    if (tokens == null || tokens.isEmpty) {
      return const SizedBox.shrink();
    }
    final baseToken = tokens.firstWhere(
      (t) => t.addrType == appState.account?.addrType,
      orElse: () => tokens.first,
    );

    final decimals =
        widget.transaction.chainType == "EVM" ? 18 : baseToken.decimals;

    final (formattedValue, convertedValue) = formatingAmount(
      amount: widget.transaction.fee,
      symbol: baseToken.symbol,
      decimals: decimals,
      rate: baseToken.rate,
      appState: appState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedValue,
          style: theme.bodyText2.copyWith(color: theme.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        if (convertedValue.isNotEmpty && convertedValue != '0')
          const SizedBox(height: 2),
        Text(
          convertedValue,
          style: theme.caption.copyWith(
            color: theme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formattedDate,
          style: theme.bodyText2.copyWith(
            color: theme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        _buildFeeWithPrice(appState, l10n),
      ],
    );
  }

  Widget _buildTransferBody(
    AppState appState,
    AppLocalizations l10n,
    HistoryAmountView view,
  ) {
    final theme = appState.currentTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIcon(appState),
            const SizedBox(width: 12),
            Expanded(child: _buildTitle(theme, l10n, view)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  view.signedNative,
                  style: theme.bodyText1.copyWith(
                    color: historyAmountColor(
                      flow: view.flow,
                      status: view.status,
                      theme: theme,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (view.fiat.isNotEmpty && view.fiat != '0') ...[
                  const SizedBox(height: 2),
                  Text(
                    view.fiat,
                    style: theme.bodyText2.copyWith(color: theme.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildBottomRow(appState, l10n),
      ],
    );
  }

  Widget _buildSignedMessageBody(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;

    return Column(
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
                            color:
                                _getStatusColor(theme).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(
                            widget.transaction.status.name.toUpperCase(),
                            style: theme.caption.copyWith(
                                color: _getStatusColor(theme),
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                            widget.transaction.title ??
                                l10n.transactionDetailsModal_transaction,
                            style: theme.bodyText1.copyWith(
                                color:
                                    theme.textPrimary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSignedMessageContent(appState),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildIcon(appState),
          ],
        ),
        const SizedBox(height: 8),
        _buildBottomRow(appState, l10n),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final view = _view;

    return Column(
      children: [
        buildPressable(
          onTap: widget.onTap,
          enableHover: true,
          child: Padding(
            padding: EdgeInsets.all(adaptivePadding),
            child: view == null
                ? _buildSignedMessageBody(state, l10n)
                : _buildTransferBody(state, l10n, view),
          ),
        ),
        if (widget.showDivider)
          Container(height: 1, color: theme.textPrimary.withValues(alpha: 0.1)),
      ],
    );
  }
}
