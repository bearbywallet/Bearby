import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockies/blockies.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showTransactionDetailsModal({
  required BuildContext context,
  required HistoricalTransactionInfo transaction,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _TransactionDetailsModalContent(
          transaction: transaction,
        ),
      );
    },
  );
}

class _TransactionDetailsModalContent extends StatelessWidget {
  final HistoricalTransactionInfo transaction;

  const _TransactionDetailsModalContent({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final double headerHeight = 84.0;
    final double itemHeight = 60.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final int infoItemsCount = _getInfoItemsCount();
    final double totalContentHeight =
        headerHeight + (itemHeight * infoItemsCount) + bottomPadding;
    final double maxHeight = MediaQuery.of(context).size.height * 0.9;
    final double containerHeight = totalContentHeight.clamp(0.0, maxHeight);

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, adaptivePadding),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: adaptivePadding,
                vertical: adaptivePadding / 2,
              ),
              child: Column(
                children: [
                  _buildTokenIcon(appState),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    context,
                    'Status',
                    _getStatusWidget(theme),
                    theme,
                  ),
                  _buildDetailItem(
                    context,
                    'Transaction Hash',
                    transaction.transactionHash,
                    theme,
                    isCopyable: true,
                  ),
                  _buildDetailItem(
                    context,
                    'Amount',
                    _formatAmount(appState),
                    theme,
                  ),
                  _buildDetailItem(
                    context,
                    'Sender',
                    transaction.sender,
                    theme,
                    isCopyable: true,
                  ),
                  _buildDetailItem(
                    context,
                    'Recipient',
                    transaction.recipient,
                    theme,
                    isCopyable: true,
                  ),
                  if (transaction.contractAddress != null)
                    _buildDetailItem(
                      context,
                      'Contract Address',
                      transaction.contractAddress!,
                      theme,
                      isCopyable: true,
                    ),
                  _buildDetailItem(
                    context,
                    'Timestamp',
                    _formatTimestamp(),
                    theme,
                  ),
                  if (transaction.blockNumber != null)
                    _buildDetailItem(
                      context,
                      'Block Number',
                      transaction.blockNumber.toString(),
                      theme,
                    ),
                  _buildDetailItem(
                    context,
                    'Fee',
                    _formatFee(appState),
                    theme,
                  ),
                  if (transaction.gasUsed != null)
                    _buildDetailItem(
                      context,
                      'Gas Used',
                      transaction.gasUsed.toString(),
                      theme,
                    ),
                  if (transaction.gasLimit != null)
                    _buildDetailItem(
                      context,
                      'Gas Limit',
                      '${transaction.gasLimit} Wei',
                      theme,
                    ),
                  if (transaction.gasPrice != null)
                    _buildDetailItem(
                      context,
                      'Gas Price',
                      _formatGasPrice(transaction.gasPrice!),
                      theme,
                    ),
                  if (transaction.effectiveGasPrice != null)
                    _buildDetailItem(
                      context,
                      'Effective Gas Price',
                      _formatGasPrice(transaction.effectiveGasPrice!),
                      theme,
                    ),
                  if (transaction.blobGasUsed != null)
                    _buildDetailItem(
                      context,
                      'Blob Gas Used',
                      transaction.blobGasUsed.toString(),
                      theme,
                    ),
                  if (transaction.blobGasPrice != null)
                    _buildDetailItem(
                      context,
                      'Blob Gas Price',
                      _formatGasPrice(transaction.blobGasPrice!),
                      theme,
                    ),
                  _buildDetailItem(
                    context,
                    'Nonce',
                    transaction.nonce.toString(),
                    theme,
                  ),
                  _buildDetailItem(
                    context,
                    'Chain Type',
                    transaction.chainType,
                    theme,
                  ),
                  _buildDetailItem(
                    context,
                    'Network',
                    _getNetworkName(appState, transaction.chainHash),
                    theme,
                  ),
                  if (transaction.error != null)
                    _buildDetailItem(
                      context,
                      'Error',
                      transaction.error!,
                      theme,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, double padding) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: EdgeInsets.symmetric(vertical: padding),
          decoration: BoxDecoration(
            color: theme.modalBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(
            transaction.title ?? 'Transaction Details',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenIcon(AppState appState) {
    final theme = appState.currentTheme;
    FTokenInfo? token;
    try {
      token = appState.wallet!.tokens.firstWhere((t) =>
          t.symbol == transaction.tokenInfo?.symbol &&
          t.addrType == appState.account?.addrType);
    } catch (e) {
      token = null;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: transaction.icon ??
              (token != null
                  ? processTokenLogo(
                      token,
                      theme.value,
                    )
                  : null),
          width: 50,
          height: 50,
          fit: BoxFit.contain,
          errorWidget: Blockies(
            seed: transaction.transactionHash,
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
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    dynamic value,
    AppTheme theme, {
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCopyable)
                  CopyContent(
                    address: value.toString(),
                    isShort: true,
                  )
                else
                  Expanded(
                    child: value is Widget
                        ? value
                        : Text(
                            value.toString(),
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusWidget(AppTheme theme) {
    switch (transaction.status) {
      case TransactionStatusInfo.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      case TransactionStatusInfo.confirmed:
        return Text(
          'Confirmed',
          style: TextStyle(
            color: theme.success,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        );
      case TransactionStatusInfo.rejected:
        return Text(
          'Rejected',
          style: TextStyle(
            color: theme.danger,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        );
    }
  }

  String _formatAmount(AppState appState) {
    final token = appState.wallet?.tokens.first;
    final amount = transaction.tokenInfo?.value ?? transaction.amount;
    final decimals = (transaction.tokenInfo?.decimals ?? token?.decimals) ?? 1;
    final symbol = (transaction.tokenInfo?.symbol ?? token?.symbol) ?? "";

    return intlNumberFormating(
      value: amount,
      decimals: decimals,
      localeStr: appState.state.locale,
      symbolStr: symbol,
      threshold: baseThreshold,
      compact: appState.state.abbreviatedNumber,
    );
  }

  String _formatFee(AppState appState) {
    final token = appState.wallet!.tokens.first;
    final decimals = transaction.chainType == "EVM" && token.decimals < 18
        ? 18
        : token.decimals;

    return intlNumberFormating(
      value: transaction.fee.toString(),
      decimals: decimals,
      localeStr: appState.state.locale,
      symbolStr: token.symbol,
      threshold: baseThreshold,
      compact: appState.state.abbreviatedNumber,
    );
  }

  String _formatTimestamp() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      transaction.timestamp.toInt() * 1000,
    );

    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _formatGasPrice(BigInt price) {
    double gwei = price / BigInt.from(10).pow(9);
    if (gwei < 1) {
      return '$price Wei';
    } else {
      return '${gwei.toString()} Gwei';
    }
  }

  String _getNetworkName(AppState appState, BigInt chainHash) {
    final chain = appState.getChain(chainHash)?.chain;
    return chain ?? 'Unknown Network ($chainHash)';
  }

  int _getInfoItemsCount() {
    int count = 11; // Базовые обязательные поля + Network вместо ChainHash
    if (transaction.contractAddress != null) count++;
    if (transaction.blockNumber != null) count++;
    if (transaction.gasUsed != null) count++;
    if (transaction.gasLimit != null) count++;
    if (transaction.gasPrice != null) count++;
    if (transaction.effectiveGasPrice != null) count++;
    if (transaction.blobGasUsed != null) count++;
    if (transaction.blobGasPrice != null) count++;
    if (transaction.error != null) count++;
    return count;
  }
}
