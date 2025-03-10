import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockies/blockies.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zilpay/components/detail_group_card.dart';
import 'package:zilpay/components/detail_item_group_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';
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
        child: TransactionDetailsModal(transaction: transaction),
      );
    },
  );
}

class TransactionDetailsModal extends StatelessWidget {
  final HistoricalTransactionInfo transaction;

  const TransactionDetailsModal({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      height: _calculateModalHeight(context, bottomPadding, maxHeight),
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
          _ModalHeader(
            title: transaction.title ?? '',
            theme: theme,
            padding: adaptivePadding,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: adaptivePadding,
                vertical: adaptivePadding / 2,
              ),
              child: Column(
                children: [
                  _AmountSection(
                    transaction: transaction,
                    appState: appState,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailsSection(context, appState, theme),
                ],
              ),
            ),
          ),
          _buildExplorerLinks(appState, adaptivePadding, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    AppState appState,
    AppTheme theme,
  ) {
    return Column(
      children: [
        DetailGroupCard(
          title: 'Transaction',
          theme: theme,
          children: [
            DetailItem(
              label: 'Hash',
              value: transaction.transactionHash,
              theme: theme,
              isCopyable: true,
            ),
            DetailItem(
              label: 'Sig',
              value: transaction.sig,
              theme: theme,
              isCopyable: true,
            ),
            DetailItem(
              label: 'Timestamp',
              value: _formatTimestamp(),
              theme: theme,
            ),
            if (transaction.blockNumber != null)
              DetailItem(
                label: 'Block Number',
                value: transaction.blockNumber.toString(),
                theme: theme,
              ),
            DetailItem(
              label: 'Nonce',
              value: transaction.nonce.toString(),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: 'Addresses',
          theme: theme,
          children: [
            DetailItem(
              label: 'Sender',
              value: transaction.sender,
              theme: theme,
              isCopyable: true,
            ),
            DetailItem(
              label: 'Recipient',
              value: transaction.recipient,
              theme: theme,
              isCopyable: true,
            ),
            if (transaction.contractAddress != null)
              DetailItem(
                label: 'Contract Address',
                value: transaction.contractAddress!,
                theme: theme,
                isCopyable: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: 'Network',
          theme: theme,
          children: [
            DetailItem(
              label: 'Chain Type',
              value: transaction.chainType,
              theme: theme,
            ),
            DetailItem(
              label: 'Network',
              value: _getNetworkName(appState, transaction.chainHash),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: 'Gas & Fees',
          theme: theme,
          children: [
            DetailItem(
              label: 'Fee',
              value: _formatFeeWidget(appState, theme),
              theme: theme,
            ),
            if (transaction.gasUsed != null)
              DetailItem(
                label: 'Gas Used',
                value: transaction.gasUsed.toString(),
                theme: theme,
              ),
            if (transaction.gasLimit != null)
              DetailItem(
                label: 'Gas Limit',
                value: '${transaction.gasLimit} Wei',
                theme: theme,
              ),
            if (transaction.gasPrice != null)
              DetailItem(
                label: 'Gas Price',
                value: _formatGasPrice(transaction.gasPrice!),
                theme: theme,
              ),
            if (transaction.effectiveGasPrice != null)
              DetailItem(
                label: 'Effective Gas Price',
                value: _formatGasPrice(transaction.effectiveGasPrice!),
                theme: theme,
              ),
            if (transaction.blobGasUsed != null)
              DetailItem(
                label: 'Blob Gas Used',
                value: transaction.blobGasUsed.toString(),
                theme: theme,
              ),
            if (transaction.blobGasPrice != null)
              DetailItem(
                label: 'Blob Gas Price',
                value: _formatGasPrice(transaction.blobGasPrice!),
                theme: theme,
              ),
          ],
        ),
        if (transaction.error != null) ...[
          const SizedBox(height: 12),
          DetailGroupCard(
            title: 'Error',
            theme: theme,
            children: [
              DetailItem(
                label: 'Error Message',
                value: transaction.error!,
                theme: theme,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExplorerLinks(
    AppState appState,
    double padding,
    double bottomPadding,
  ) {
    final theme = appState.currentTheme;
    final chain = appState.getChain(transaction.chainHash);
    final explorers = chain?.explorers ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: theme.modalBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: explorers.isEmpty
            ? [
                _buildDefaultExplorerButton(theme),
              ]
            : explorers
                .map((explorer) => _buildExplorerButton(explorer, theme))
                .toList(),
      ),
    );
  }

  Widget _buildExplorerButton(ExplorerInfo explorer, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () async {
          final url = formExplorerUrl(explorer, transaction.transactionHash);

          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryPurple.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: _buildExplorerIcon(explorer, theme),
        ),
      ),
    );
  }

  Widget _buildExplorerIcon(ExplorerInfo explorer, AppTheme theme) {
    if (explorer.icon != null) {
      return AsyncImage(
        url: preprocessUrl(explorer.icon!, theme.value),
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        errorWidget: _buildFallbackIcon(explorer.name, theme),
        loadingWidget: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryPurple),
          ),
        ),
      );
    }

    return _buildFallbackIcon(explorer.name, theme);
  }

  Widget _buildFallbackIcon(String explorerName, AppTheme theme) {
    final firstLetter =
        explorerName.isNotEmpty ? explorerName[0].toUpperCase() : 'E';

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.secondaryPurple,
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            color: theme.background,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultExplorerButton(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryPurple.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.open_in_new,
            size: 20,
            color: theme.primaryPurple,
          ),
        ),
      ),
    );
  }

  Widget _formatFeeWidget(AppState appState, AppTheme theme) {
    final (amount, converted) = _formatFee(appState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          amount,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        ),
        if (converted.isNotEmpty && converted != '0')
          Text(
            converted,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.right,
          ),
      ],
    );
  }

  double _calculateModalHeight(
      BuildContext context, double bottomPadding, double maxHeight) {
    const double headerHeight = 84.0;
    const double transferSectionHeight = 160.0;
    const double detailGroupHeight = 70.0;
    const double explorerLinksHeight = 60.0;

    const int baseGroupsCount = 4;
    int additionalGroups = transaction.error != null ? 1 : 0;

    final totalContentHeight = headerHeight +
        transferSectionHeight +
        (detailGroupHeight * (baseGroupsCount + additionalGroups)) +
        explorerLinksHeight +
        bottomPadding;

    return totalContentHeight.clamp(0.0, maxHeight);
  }

  (String, String) _formatFee(AppState appState) {
    final token = appState.wallet?.tokens.first;
    if (token == null) {
      return ('0', '');
    }

    final decimals = transaction.chainType == "EVM" && token.decimals < 18
        ? 18
        : token.decimals;

    return formatingAmount(
      amount: transaction.fee,
      symbol: token.symbol,
      decimals: decimals,
      rate: token.rate,
      appState: appState,
    );
  }

  String _formatTimestamp() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      transaction.timestamp.toInt() * 1000,
    );

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _formatGasPrice(BigInt price) {
    final gwei = price / BigInt.from(10).pow(9);
    if (gwei < 1) {
      return '$price Wei';
    } else {
      return '$gwei Gwei';
    }
  }

  String _getNetworkName(AppState appState, BigInt chainHash) {
    final chain = appState.getChain(chainHash)?.chain;
    return chain ?? 'Unknown Network ($chainHash)';
  }
}

class _AmountSection extends StatelessWidget {
  final HistoricalTransactionInfo transaction;
  final AppState appState;
  final AppTheme theme;

  const _AmountSection({
    required this.transaction,
    required this.appState,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: 'Transfer',
      theme: theme,
      headerTrailing: _buildStatusWidget(theme),
      children: [
        _buildTokenTransferInfo(),
      ],
    );
  }

  Widget _buildStatusWidget(AppTheme theme) {
    switch (transaction.status) {
      case TransactionStatusInfo.pending:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Pending',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case TransactionStatusInfo.confirmed:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Confirmed',
            style: TextStyle(
              color: theme.success,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case TransactionStatusInfo.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Rejected',
            style: TextStyle(
              color: theme.danger,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  Widget _buildTokenTransferInfo() {
    final (amount, converted) = _formatAmount();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildTokenIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (converted.isNotEmpty && converted != '0')
                  Text(
                    converted,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenIcon() {
    final theme = appState.currentTheme;
    final token = _findMatchingToken();

    return Container(
      width: 45,
      height: 45,
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
              (token != null ? processTokenLogo(token, theme.value) : null),
          width: 45,
          height: 45,
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

  (String, String) _formatAmount() {
    final token = appState.wallet?.tokens.first;
    final amount =
        BigInt.tryParse(transaction.tokenInfo?.value ?? transaction.amount) ??
            BigInt.zero;
    final decimals = (transaction.tokenInfo?.decimals ?? token?.decimals) ?? 1;
    final symbol = (transaction.tokenInfo?.symbol ?? token?.symbol) ?? "";

    return formatingAmount(
      amount: amount,
      symbol: symbol,
      decimals: decimals,
      rate: token?.rate ?? 0,
      appState: appState,
    );
  }

  FTokenInfo? _findMatchingToken() {
    if (appState.wallet == null ||
        transaction.tokenInfo == null ||
        appState.account == null) {
      return null;
    }

    try {
      return appState.wallet!.tokens.firstWhere((t) =>
          t.symbol == transaction.tokenInfo?.symbol &&
          t.addrType == appState.account?.addrType);
    } catch (_) {
      return null;
    }
  }
}

class _ModalHeader extends StatelessWidget {
  final String title;
  final AppTheme theme;
  final double padding;

  const _ModalHeader({
    required this.title,
    required this.theme,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
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
        if (title != '')
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SizedBox(height: padding),
      ],
    );
  }
}
