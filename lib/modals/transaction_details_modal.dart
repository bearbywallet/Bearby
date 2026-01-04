import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zilpay/components/detail_group_card.dart';
import 'package:zilpay/components/detail_item_group_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/transaction_parsing.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    if (transaction.isSignedMessage) {
      return _buildSignedMessageDetails(context, appState, theme, l10n);
    }

    if (transaction.isBtcTransaction) {
      return _buildBtcDetails(context, appState, theme, l10n);
    }

    return Column(
      children: [
        DetailGroupCard(
          title: l10n.transactionDetailsModal_transaction,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_hash,
              value: transaction.transactionHash,
              theme: theme,
              isCopyable: true,
            ),
            if (transaction.sig != null)
              DetailItem(
                label: l10n.transactionDetailsModal_sig,
                value: transaction.sig!,
                theme: theme,
                isCopyable: true,
              ),
            DetailItem(
              label: l10n.transactionDetailsModal_timestamp,
              value: _formatTimestamp(),
              theme: theme,
            ),
            if (transaction.statusCode != null)
              DetailItem(
                label: 'Status Code',
                value: transaction.statusCode.toString(),
                theme: theme,
              ),
            if (transaction.blockNumber != null)
              DetailItem(
                label: l10n.transactionDetailsModal_blockNumber,
                value: transaction.blockNumber.toString(),
                theme: theme,
              ),
            if (transaction.nonce != null)
              DetailItem(
                label: l10n.transactionDetailsModal_nonce,
                value: transaction.nonce.toString(),
                theme: theme,
              ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: l10n.transactionDetailsModal_addresses,
          theme: theme,
          children: [
            if (transaction.sender.isNotEmpty)
              DetailItem(
                label: l10n.transactionDetailsModal_sender,
                value: transaction.sender,
                theme: theme,
                isCopyable: true,
              ),
            if (transaction.recipient.isNotEmpty)
              DetailItem(
                label: l10n.transactionDetailsModal_recipient,
                value: transaction.recipient,
                theme: theme,
                isCopyable: true,
              ),
            if (transaction.contractAddress != null)
              DetailItem(
                label: l10n.transactionDetailsModal_contractAddress,
                value: transaction.contractAddress!,
                theme: theme,
                isCopyable: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: l10n.transactionDetailsModal_network,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_chainType,
              value: transaction.chainType,
              theme: theme,
            ),
            DetailItem(
              label: l10n.transactionDetailsModal_networkName,
              value: _getNetworkName(appState, transaction.chainHash),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: l10n.transactionDetailsModal_gasFees,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_fee,
              value: _formatFeeWidget(appState, theme),
              theme: theme,
            ),
            if (transaction.gasUsed != null)
              DetailItem(
                label: l10n.transactionDetailsModal_gasUsed,
                value: transaction.gasUsed.toString(),
                theme: theme,
              ),
            if (transaction.gasLimit != null)
              DetailItem(
                label: l10n.transactionDetailsModal_gasLimit,
                value: '${transaction.gasLimit} Wei',
                theme: theme,
              ),
            if (transaction.gasPrice != null)
              DetailItem(
                label: l10n.transactionDetailsModal_gasPrice,
                value: _formatGasPrice(transaction.gasPrice!),
                theme: theme,
              ),
            if (transaction.effectiveGasPrice != null)
              DetailItem(
                label: l10n.transactionDetailsModal_effectiveGasPrice,
                value: _formatGasPrice(transaction.effectiveGasPrice!),
                theme: theme,
              ),
            if (transaction.blobGasUsed != null)
              DetailItem(
                label: l10n.transactionDetailsModal_blobGasUsed,
                value: transaction.blobGasUsed.toString(),
                theme: theme,
              ),
            if (transaction.blobGasPrice != null)
              DetailItem(
                label: l10n.transactionDetailsModal_blobGasPrice,
                value: _formatGasPrice(transaction.blobGasPrice!),
                theme: theme,
              ),
          ],
        ),
        if (transaction.error != null) ...[
          const SizedBox(height: 12),
          DetailGroupCard(
            title: l10n.transactionDetailsModal_error,
            theme: theme,
            children: [
              DetailItem(
                label: l10n.transactionDetailsModal_errorMessage,
                value: transaction.error!,
                theme: theme,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSignedMessageDetails(
    BuildContext context,
    AppState appState,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    final signedMsg = transaction.parsedSignedMessage;

    return Column(
      children: [
        DetailGroupCard(
          title: l10n.signMessageModalContentTitle,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.signedMessageType,
              value: _getLocalizedSignType(signedMsg, l10n),
              theme: theme,
            ),
            if (signedMsg?.signer != null)
              DetailItem(
                label: l10n.signedMessageSigner,
                value: signedMsg!.signer!,
                theme: theme,
                isCopyable: true,
              ),
            if (signedMsg?.signature != null)
              DetailItem(
                label: l10n.transactionDetailsModal_sig,
                value: signedMsg!.signature!,
                theme: theme,
                isCopyable: true,
              ),
            if (signedMsg?.pubKey != null)
              DetailItem(
                label: l10n.signedMessagePublicKey,
                value: signedMsg!.pubKey!,
                theme: theme,
                isCopyable: true,
              ),
            DetailItem(
              label: l10n.transactionDetailsModal_timestamp,
              value: _formatTimestamp(),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: l10n.transactionDetailsModal_network,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_networkName,
              value: _getNetworkName(appState, transaction.chainHash),
              theme: theme,
            ),
          ],
        ),
        if (signedMsg?.isTypedData == true) ...[
          const SizedBox(height: 12),
          DetailGroupCard(
            title: l10n.signedMessageEip712Domain,
            theme: theme,
            children: [
              if (signedMsg?.domainName != null)
                DetailItem(
                  label: l10n.signedMessageDomainName,
                  value: signedMsg!.domainName!,
                  theme: theme,
                ),
              if (signedMsg?.domainChainId != null)
                DetailItem(
                  label: l10n.signedMessageDomainChainId,
                  value: signedMsg!.domainChainId.toString(),
                  theme: theme,
                ),
              if (signedMsg?.domainContract != null)
                DetailItem(
                  label: l10n.signedMessageDomainContract,
                  value: signedMsg!.domainContract!,
                  theme: theme,
                  isCopyable: true,
                ),
              if (signedMsg?.primaryType != null)
                DetailItem(
                  label: l10n.signedMessagePrimaryType,
                  value: signedMsg!.primaryType!,
                  theme: theme,
                ),
            ],
          ),
          if (signedMsg?.typedMessage != null) ...[
            const SizedBox(height: 12),
            DetailGroupCard(
              title: l10n.signedMessageData,
              theme: theme,
              children: [
                ...signedMsg!.typedMessage!.entries.map(
                  (e) => DetailItem(
                    label: e.key,
                    value: e.value is Map || e.value is List
                        ? _formatJsonValue(e.value)
                        : e.value.toString(),
                    theme: theme,
                    isCopyable: true,
                  ),
                ),
              ],
            ),
          ],
        ],
        if (signedMsg?.isPersonalSign == true &&
            signedMsg?.message != null) ...[
          const SizedBox(height: 12),
          DetailGroupCard(
            title: l10n.signedMessageMessage,
            theme: theme,
            children: [
              DetailItem(
                label: l10n.signedMessageContent,
                value: signedMsg!.decodedMessage,
                theme: theme,
                isCopyable: true,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBtcDetails(
    BuildContext context,
    AppState appState,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    final btcReceipt = transaction.btcReceipt;

    return Column(
      children: [
        DetailGroupCard(
          title: l10n.transactionDetailsModal_transaction,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_hash,
              value: transaction.transactionHash,
              theme: theme,
              isCopyable: true,
            ),
            if (btcReceipt?.confirmations != null)
              DetailItem(
                label: 'Confirmations',
                value: btcReceipt!.confirmations.toString(),
                theme: theme,
              ),
            DetailItem(
              label: l10n.transactionDetailsModal_timestamp,
              value: _formatTimestamp(),
              theme: theme,
            ),
            if (btcReceipt?.lockTime != null)
              DetailItem(
                label: 'Lock Time',
                value: btcReceipt!.lockTime.toString(),
                theme: theme,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (btcReceipt?.inputs != null && btcReceipt!.inputs!.isNotEmpty) ...[
          DetailGroupCard(
            title: 'Inputs (${btcReceipt.inputsCount ?? btcReceipt.inputs!.length})',
            theme: theme,
            children: btcReceipt.inputs!.take(3).map((input) {
              return DetailItem(
                label: 'TXID',
                value: '${input.txid ?? 'N/A'}:${input.vout ?? 0}',
                theme: theme,
                isCopyable: true,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (btcReceipt?.outputs != null && btcReceipt!.outputs!.isNotEmpty) ...[
          DetailGroupCard(
            title: 'Outputs (${btcReceipt.outputsCount ?? btcReceipt.outputs!.length})',
            theme: theme,
            children: btcReceipt.outputs!.take(3).map((output) {
              final token = appState.wallet?.tokens.first;
              final decimals = transaction.tokenInfo?.decimals ?? token?.decimals ?? 8;
              final symbol = transaction.tokenInfo?.symbol ?? token?.symbol ?? 'BTC';

              final (formattedValue, _) = formatingAmount(
                amount: output.value ?? BigInt.zero,
                symbol: symbol,
                decimals: decimals,
                rate: 0,
                appState: appState,
              );

              return DetailItem(
                label: formattedValue,
                value: output.address ?? output.scriptPubKeyHex ?? 'N/A',
                theme: theme,
                isCopyable: true,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        DetailGroupCard(
          title: l10n.transactionDetailsModal_network,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_chainType,
              value: transaction.chainType,
              theme: theme,
            ),
            DetailItem(
              label: l10n.transactionDetailsModal_networkName,
              value: _getNetworkName(appState, transaction.chainHash),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailGroupCard(
          title: l10n.transactionDetailsModal_gasFees,
          theme: theme,
          children: [
            DetailItem(
              label: l10n.transactionDetailsModal_fee,
              value: _formatFeeWidget(appState, theme),
              theme: theme,
            ),
          ],
        ),
        if (transaction.error != null) ...[
          const SizedBox(height: 12),
          DetailGroupCard(
            title: l10n.transactionDetailsModal_error,
            theme: theme,
            children: [
              DetailItem(
                label: l10n.transactionDetailsModal_errorMessage,
                value: transaction.error!,
                theme: theme,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getLocalizedSignType(ParsedSignedMessage? signedMsg, AppLocalizations l10n) {
    if (signedMsg == null) return l10n.signedMessageTypeUnknown;
    if (signedMsg.isPersonalSign) return l10n.signedMessageTypePersonalSign;
    if (signedMsg.isTypedData) return l10n.signedMessageTypeEip712;
    return l10n.signedMessageTypeUnknown;
  }

  String _formatJsonValue(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
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
      child: SafeArea(
        bottom: true,
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
        url: processUrl(explorer.icon!, theme.value),
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
          style: theme.labelSmall.copyWith(
            color: theme.background,
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
          style: theme.labelMedium.copyWith(
            color: theme.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        if (converted.isNotEmpty && converted != '0')
          Text(
            converted,
            style: theme.labelSmall.copyWith(
              color: theme.textSecondary,
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
    final baseToken = appState.wallet?.tokens.firstWhere(
      (t) => t.addrType == appState.account?.addrType,
      orElse: () => appState.wallet!.tokens.first,
    );

    if (baseToken == null) {
      return ('0', '');
    }

    final decimals = transaction.chainType == "EVM" && baseToken.decimals < 18
        ? 18
        : baseToken.decimals;

    return formatingAmount(
      amount: transaction.fee,
      symbol: baseToken.symbol,
      decimals: decimals,
      rate: baseToken.rate,
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
    final l10n = AppLocalizations.of(context)!;

    if (transaction.isSignedMessage) {
      return DetailGroupCard(
        title: l10n.signMessageModalContentTitle,
        theme: theme,
        headerTrailing: _buildStatusWidget(context, theme),
        children: [
          _buildSignedMessageInfo(l10n),
        ],
      );
    }

    return DetailGroupCard(
      title: l10n.amountSection_transfer,
      theme: theme,
      headerTrailing: _buildStatusWidget(context, theme),
      children: [
        _buildTokenTransferInfo(),
      ],
    );
  }

  Widget _buildSignedMessageInfo(AppLocalizations l10n) {
    final signedMsg = transaction.parsedSignedMessage;
    if (signedMsg == null) {
      return const SizedBox.shrink();
    }

    String displayContent;
    String subtitle;
    String badgeText;

    if (signedMsg.isTypedData) {
      final domainName = signedMsg.domainName ?? l10n.signedMessageTypeUnknown;
      final primaryType = signedMsg.primaryType ?? '';
      displayContent = domainName;
      subtitle = primaryType.isNotEmpty ? primaryType : l10n.signedMessageTypeEip712;
      badgeText = l10n.signedMessageTypeEip712;
    } else {
      displayContent = signedMsg.decodedMessage;
      subtitle = l10n.signedMessageTypePersonalSign;
      badgeText = l10n.signedMessageTypePersonalSign;
    }

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.title ?? l10n.signMessageModalContentTitle,
                        style: theme.subtitle1.copyWith(color: theme.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.bodyText2.copyWith(color: theme.textSecondary),
                ),
                if (displayContent.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    displayContent,
                    style: theme.bodyText1.copyWith(color: theme.textPrimary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, AppTheme theme) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.amountSection_pending,
                style: theme.labelMedium.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      case TransactionStatusInfo.success:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.amountSection_confirmed,
            style: theme.labelMedium.copyWith(
              color: theme.success,
            ),
          ),
        );
      case TransactionStatusInfo.failed:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.amountSection_rejected,
            style: theme.labelMedium.copyWith(
              color: theme.danger,
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
                  style: theme.titleMedium.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                if (converted.isNotEmpty && converted != '0')
                  Text(
                    converted,
                    style: theme.bodyText2.copyWith(
                      color: theme.textSecondary,
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
              (token != null
                  ? processTokenLogo(
                      token: token,
                      shortName: appState.chain?.shortName ?? "",
                      theme: theme.value,
                    )
                  : null),
          width: 45,
          height: 45,
          fit: BoxFit.contain,
          errorWidget: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.background,
            ),
            child: SvgPicture.asset(
              'assets/icons/warning.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                theme.textSecondary,
                BlendMode.srcIn,
              ),
            ),
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
              style: theme.titleMedium.copyWith(
                color: theme.textPrimary,
              ),
            ),
          ),
        SizedBox(height: padding),
      ],
    );
  }
}
