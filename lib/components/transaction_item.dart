import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/transaction_parsing.dart';
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
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  Widget _buildIcon(AppState appState) {
    final theme = appState.currentTheme;
    final token = _findMatchingToken(appState);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: theme.primaryPurple.withValues(alpha: 0.1), width: 2)),
      child: ClipOval(
        child: AsyncImage(
          url: widget.transaction.icon ??
              (token != null
                  ? processTokenLogo(
                      token: token,
                      shortName: appState.chain?.shortName ?? "",
                      theme: theme.value,
                    )
                  : null),
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorWidget: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.background,
            ),
            child: SvgPicture.asset(
              'assets/icons/warning.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                theme.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          loadingWidget:
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  FTokenInfo? _findMatchingToken(AppState appState) {
    if (appState.wallet == null ||
        widget.transaction.tokenInfo == null ||
        appState.account == null) {
      return null;
    }

    try {
      return appState.wallet!.tokens.firstWhere((t) =>
          t.symbol == widget.transaction.tokenInfo?.symbol &&
          t.addrType == appState.account?.addrType);
    } catch (_) {
      return null;
    }
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

  Widget _buildAmountWithPrice(AppState appState) {
    final theme = appState.currentTheme;

    if (widget.transaction.isSignedMessage) {
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayContent.isNotEmpty ? displayContent : 'Signed Message',
            style: theme.bodyText1.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      );
    }

    final token = _findMatchingToken(appState);
    final baseToken = appState.wallet?.tokens.first;

    final amount = BigInt.tryParse(
            widget.transaction.tokenInfo?.value ?? widget.transaction.amount) ??
        BigInt.zero;

    final decimals = (widget.transaction.tokenInfo?.decimals ??
            token?.decimals ??
            baseToken?.decimals) ??
        1;

    final symbol = (widget.transaction.tokenInfo?.symbol ??
            token?.symbol ??
            baseToken?.symbol) ??
        "";

    final rate = token?.rate ?? baseToken?.rate ?? 0;

    final (formattedValue, convertedValue) = formatingAmount(
      amount: amount,
      symbol: symbol,
      decimals: decimals,
      rate: rate,
      appState: appState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedValue,
            style: theme.bodyText1.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis),
        if (convertedValue.isNotEmpty && convertedValue != '0')
          const SizedBox(height: 2),
        Text(convertedValue,
            style: theme.bodyText2
                .copyWith(color: theme.textSecondary.withValues(alpha: 0.7))),
      ],
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

    final token = appState.wallet?.tokens.first;

    if (token == null) {
      return const SizedBox.shrink();
    }

    final decimals =
        widget.transaction.chainType == "EVM" && token.decimals < 18
            ? 18
            : token.decimals;

    final (formattedValue, convertedValue) = formatingAmount(
      amount: widget.transaction.fee,
      symbol: token.symbol,
      decimals: decimals,
      rate: token.rate,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Column(
      children: [
        buildPressable(
          onTap: widget.onTap,
          enableHover: true,
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
                                    style: theme.caption.copyWith(
                                        color: _getStatusColor(theme),
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                    widget.transaction.title ??
                                        l10n
                                            .transactionDetailsModal_transaction,
                                    style: theme.bodyText1.copyWith(
                                        color: theme.textPrimary
                                            .withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildAmountWithPrice(state),
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
                    Text(
                      _formatDateTime(),
                      style: theme.bodyText2.copyWith(
                        color: theme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    _buildFeeWithPrice(state, l10n),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Container(height: 1, color: theme.textPrimary.withValues(alpha: 0.1)),
      ],
    );
  }
}
