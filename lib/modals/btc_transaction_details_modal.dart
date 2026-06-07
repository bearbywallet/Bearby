import 'package:bearby/mixins/preprocess_url.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bearby/components/copy_content.dart';
import 'package:bearby/components/detail_group_card.dart';
import 'package:bearby/components/detail_item_group_card.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/transactions/btc.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

final BigInt _kMaxSequence = BigInt.from(0xFFFFFFFE);

extension BtcTransactionDetailsExt on TransactionBitcoin {
  bool get isCoinbase {
    final firstInput = input.firstOrNull;
    if (firstInput == null) return false;
    return firstInput.previousOutput.txid ==
            '0000000000000000000000000000000000000000000000000000000000000000' &&
        firstInput.previousOutput.vout == 0xFFFFFFFF;
  }

  bool get hasWitness => input.any((i) => i.witness.isNotEmpty);
  bool get isRbf => input.any((i) => BigInt.from(i.sequence) < _kMaxSequence);
  BigInt get outputValue =>
      output.fold<BigInt>(BigInt.zero, (sum, o) => sum + o.value);
  BigInt get inputValue => fee != null ? outputValue + fee! : outputValue;
}

void showBtcTransactionDetailsModal({
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
    builder: (_) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: BtcTransactionDetailsModal(transaction: transaction),
    ),
  );
}

class BtcTransactionDetailsModal extends StatelessWidget {
  final HistoricalTransactionInfo transaction;

  const BtcTransactionDetailsModal({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final pad = AdaptiveSize.getAdaptivePadding(context, 16);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.9;
    final btc = transaction.btcReceipt;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(theme: theme, padding: pad),
          if (transaction.title?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
              child: Text(
                transaction.title!,
                style: theme.titleMedium.copyWith(color: theme.textPrimary),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Column(
                children: [
                  _AmountCard(
                    transaction: transaction,
                    appState: appState,
                    theme: theme,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionGroup(context, theme, l10n),
                  if (btc != null &&
                      !btc.isCoinbase &&
                      btc.input.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildFromGroup(btc, theme, l10n),
                  ],
                  if (btc != null && btc.output.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildToGroup(btc, appState, theme, l10n),
                  ],
                  const SizedBox(height: 12),
                  _buildNetworkGroup(appState, theme, l10n),
                  const SizedBox(height: 12),
                  _buildFeesPropertiesGroup(appState, theme, l10n),
                  if (transaction.error != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorGroup(theme, l10n),
                  ],
                  SizedBox(height: bottomPad + 16),
                ],
              ),
            ),
          ),
          _ExplorerFooter(
            transaction: transaction,
            appState: appState,
            padding: pad,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionGroup(
    BuildContext context,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    return DetailGroupCard(
      title: l10n.transactionDetailsModal_transaction,
      theme: theme,
      children: [
        DetailItem(
          label: l10n.transactionDetailsModal_hash,
          value: transaction.transactionHash,
          theme: theme,
          isCopyable: true,
        ),
        DetailItem(
          label: l10n.transactionDetailsModal_timestamp,
          value: _formatTimestamp(context),
          theme: theme,
        ),
        DetailItem(
          label: l10n.transactionDetailsModal_age,
          value: _formatAge(),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildFromGroup(
    TransactionBitcoin btc,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    return DetailGroupCard(
      title: l10n.transactionDetailsModal_from,
      theme: theme,
      children: [
        const SizedBox(height: 4),
        ...btc.input.asMap().entries.map(
              (e) => _InputRow(
                index: e.key + 1,
                input: e.value,
                theme: theme,
              ),
            ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildToGroup(
    TransactionBitcoin btc,
    AppState appState,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    final baseToken = appState.wallet?.tokens.first;
    final decimals = baseToken?.decimals ?? 8;
    final symbol = baseToken?.symbol ?? 'BTC';

    return DetailGroupCard(
      title: l10n.transactionDetailsModal_to,
      theme: theme,
      children: [
        const SizedBox(height: 4),
        ...btc.output.asMap().entries.map(
              (e) => _OutputRow(
                index: e.key + 1,
                output: e.value,
                theme: theme,
                appState: appState,
                decimals: decimals,
                symbol: symbol,
              ),
            ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildNetworkGroup(
    AppState appState,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    return DetailGroupCard(
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
          value: appState.getChain(transaction.chainHash)?.chain ?? 'Unknown',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildFeesPropertiesGroup(
    AppState appState,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    final btc = transaction.btcReceipt;
    final baseToken = appState.wallet?.tokens.first;
    final decimals = baseToken?.decimals ?? 8;
    final symbol = baseToken?.symbol ?? 'BTC';
    final rate = baseToken?.rate ?? 0;

    final feeKnown = btc?.fee != null;
    final (feeStr, feeFiat) = feeKnown
        ? formatingAmount(
            amount: transaction.fee,
            symbol: symbol,
            decimals: decimals,
            rate: rate,
            appState: appState,
          )
        : ('—', '');

    final inputValueStr = btc != null
        ? formatingAmount(
            amount: btc.inputValue,
            symbol: symbol,
            decimals: decimals,
            rate: rate,
            appState: appState,
          ).$1
        : '0';

    final outputValueStr = btc != null
        ? formatingAmount(
            amount: btc.outputValue,
            symbol: symbol,
            decimals: decimals,
            rate: rate,
            appState: appState,
          ).$1
        : '0';

    final btcPriceFiat = rate > 0
        ? formatingAmount(
            amount: BigInt.from(10).pow(decimals),
            symbol: symbol,
            decimals: decimals,
            rate: rate,
            appState: appState,
          ).$2
        : '';
    final showBtcPrice = btcPriceFiat.isNotEmpty && btcPriceFiat != '0';

    final showCoinbase = btc?.isCoinbase == true;
    final showRbf = btc?.isRbf == true;
    final showLocktime = btc != null && btc.lockTime > 0;

    return DetailGroupCard(
      title: l10n.transactionDetailsModal_feesProperties,
      theme: theme,
      children: [
        DetailItem(
          label: l10n.transactionDetailsModal_fee,
          theme: theme,
          valueWidget:
              _AmountValue(amount: feeStr, fiat: feeFiat, theme: theme),
        ),
        DetailItem(
          label: l10n.transactionDetailsModal_inputValue,
          value: inputValueStr,
          theme: theme,
        ),
        DetailItem(
          label: l10n.transactionDetailsModal_outputValue,
          value: outputValueStr,
          theme: theme,
        ),
        if (showBtcPrice)
          DetailItem(
            label: l10n.transactionDetailsModal_btcPrice,
            value: btcPriceFiat,
            theme: theme,
          ),
        if (showCoinbase)
          DetailItem(
            label: l10n.transactionDetailsModal_coinbase,
            value: l10n.chainInfoModalContentYes,
            theme: theme,
          ),
        if (showRbf)
          DetailItem(
            label: l10n.transactionDetailsModal_rbf,
            value: l10n.chainInfoModalContentYes,
            theme: theme,
          ),
        if (showLocktime)
          DetailItem(
            label: l10n.transactionDetailsModal_locktime,
            value: btc.lockTime.toString(),
            theme: theme,
          ),
        if (btc != null)
          DetailItem(
            label: l10n.transactionDetailsModal_version,
            value: btc.version.toString(),
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildErrorGroup(AppTheme theme, AppLocalizations l10n) {
    return DetailGroupCard(
      title: l10n.transactionDetailsModal_error,
      theme: theme,
      children: [
        DetailItem(
          label: l10n.transactionDetailsModal_errorMessage,
          value: transaction.error!,
          theme: theme,
        ),
      ],
    );
  }

  String _formatTimestamp(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
      transaction.timestamp.toInt() * 1000,
    );
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('dd MMM yyyy HH:mm', locale).format(dt);
  }

  String _formatAge() {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(transaction.timestamp.toInt() * 1000),
    );
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _AmountCard extends StatelessWidget {
  final HistoricalTransactionInfo transaction;
  final AppState appState;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _AmountCard({
    required this.transaction,
    required this.appState,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: l10n.amountSection_transfer,
      theme: theme,
      headerTrailing:
          _StatusBadge(status: transaction.status, theme: theme, l10n: l10n),
      children: [_buildBody()],
    );
  }

  Widget _buildBody() {
    final (amount, fiat) = _formatAmount();
    final btc = transaction.btcReceipt;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: theme.titleMedium.copyWith(color: theme.textPrimary),
                ),
                if (fiat.isNotEmpty && fiat != '0')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      fiat,
                      style:
                          theme.bodyText2.copyWith(color: theme.textSecondary),
                    ),
                  ),
                if (btc != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.transactionDetailsModal_inputsOutputsSummary(
                        btc.input.length,
                        btc.output.length,
                      ),
                      style: theme.caption.copyWith(
                        color: theme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final token = _findMatchingToken();
    return TokenAvatar(
      token: token,
      size: 44,
      appState: appState,
      showNetworkBadge: false,
      iconUrl: transaction.icon,
      borderColor: theme.primaryPurple.withValues(alpha: 0.12),
      borderWidth: 1.5,
      fit: BoxFit.contain,
    );
  }

  (String, String) _formatAmount() {
    final token = appState.wallet?.tokens.first;
    final amount =
        BigInt.tryParse(transaction.tokenInfo?.value ?? transaction.amount) ??
            BigInt.zero;
    final decimals = (transaction.tokenInfo?.decimals ?? token?.decimals) ?? 1;
    final symbol = (transaction.tokenInfo?.symbol ?? token?.symbol) ?? '';
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

class _StatusBadge extends StatelessWidget {
  final TransactionStatusInfo status;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _StatusBadge({
    required this.status,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TransactionStatusInfo.pending:
        return _wrap(
          color: Colors.orange,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.amountSection_pending,
                style: theme.labelMedium.copyWith(color: Colors.orange),
              ),
            ],
          ),
        );
      case TransactionStatusInfo.success:
        return _wrap(
          color: theme.success,
          child: Text(
            l10n.amountSection_confirmed,
            style: theme.labelMedium.copyWith(color: theme.success),
          ),
        );
      case TransactionStatusInfo.failed:
        return _wrap(
          color: theme.danger,
          child: Text(
            l10n.amountSection_rejected,
            style: theme.labelMedium.copyWith(color: theme.danger),
          ),
        );
    }
  }

  Widget _wrap({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _AmountValue extends StatelessWidget {
  final String amount;
  final String fiat;
  final AppTheme theme;

  const _AmountValue({
    required this.amount,
    required this.fiat,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          amount,
          style: theme.bodyText2.copyWith(color: theme.textPrimary),
          textAlign: TextAlign.right,
        ),
        if (fiat.isNotEmpty && fiat != '0')
          Text(
            fiat,
            style: theme.bodyText2.copyWith(
              color: theme.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  final int index;
  final TxInInfo input;
  final AppTheme theme;

  const _InputRow({
    required this.index,
    required this.input,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final addr = input.address;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              style: theme.bodyText2.copyWith(
                color: theme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (addr != null)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: CopyContent(address: addr),
              ),
            )
          else
            Expanded(
              child: Text(
                '${shortenAddress(input.previousOutput.txid)}:${input.previousOutput.vout}',
                style: theme.bodyText2.copyWith(color: theme.textSecondary),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  final int index;
  final TxOutInfo output;
  final AppTheme theme;
  final AppState appState;
  final int decimals;
  final String symbol;

  const _OutputRow({
    required this.index,
    required this.output,
    required this.theme,
    required this.appState,
    required this.decimals,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final addr = output.address;
    final (formatted, _) = formatingAmount(
      amount: output.value,
      symbol: symbol,
      decimals: decimals,
      rate: 0,
      appState: appState,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              style: theme.bodyText2.copyWith(
                color: theme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: addr != null
                  ? CopyContent(address: addr)
                  : Text(
                      '—',
                      style:
                          theme.bodyText2.copyWith(color: theme.textSecondary),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatted,
            style: theme.bodyText2.copyWith(color: theme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final AppTheme theme;
  final double padding;

  const _DragHandle({required this.theme, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: EdgeInsets.only(top: padding, bottom: padding / 2),
        decoration: BoxDecoration(
          color: theme.modalBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ExplorerFooter extends StatelessWidget {
  final HistoricalTransactionInfo transaction;
  final AppState appState;
  final double padding;

  const _ExplorerFooter({
    required this.transaction,
    required this.appState,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = appState.currentTheme;
    final explorers = appState.getChain(transaction.chainHash)?.explorers ?? [];
    if (explorers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: theme.modalBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: explorers.map((e) => _explorerBtn(e, theme)).toList(),
        ),
      ),
    );
  }

  Widget _explorerBtn(ExplorerInfo explorer, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final url = formExplorerUrl(explorer, transaction.transactionHash);
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: explorer.icon != null
              ? AsyncImage(
                  url: processUrl(explorer.icon!, theme.value),
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                )
              : Icon(Icons.open_in_new, size: 18, color: theme.primaryPurple),
        ),
      ),
    );
  }
}
