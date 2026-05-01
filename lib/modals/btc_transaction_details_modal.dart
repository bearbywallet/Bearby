import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/preprocess_url.dart';
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
  BigInt get inputValue =>
      fee != null ? outputValue + fee! : outputValue;
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: BtcTransactionDetailsModal(transaction: transaction),
    ),
  );
}

class BtcTransactionDetailsModal extends StatelessWidget {
  final HistoricalTransactionInfo transaction;

  const BtcTransactionDetailsModal({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final pad = AdaptiveSize.getAdaptivePadding(context, 16);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(theme, pad),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusAmountRow(theme: theme, transaction: transaction, appState: appState),
                  const SizedBox(height: 20),
                  _buildFromSection(theme),
                  const SizedBox(height: 16),
                  _buildToSection(appState, theme),
                  const SizedBox(height: 16),
                  _buildOverview(context, appState, theme),
                  const SizedBox(height: 16),
                  _buildNetwork(appState, theme),
                  if (transaction.error != null) ...[
                    const SizedBox(height: 12),
                    _SectionHeader(title: 'Error', theme: theme),
                    const SizedBox(height: 8),
                    _FieldRow(label: 'Error Message', value: transaction.error!, theme: theme),
                  ],
                  SizedBox(height: bottomPad + 16),
                ],
              ),
            ),
          ),
          _buildExplorerFooter(appState, pad),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context, AppState appState, AppTheme theme) {
    final btc = transaction.btcReceipt;
    final baseToken = appState.wallet?.tokens.first;
    final decimals = baseToken?.decimals ?? 8;
    final symbol = baseToken?.symbol ?? 'BTC';
    final rate = baseToken?.rate ?? 0;

    final feeKnown = btc?.fee != null;

    final (feeStr, feeFiat) = feeKnown
        ? formatingAmount(
            amount: transaction.fee, symbol: symbol, decimals: decimals, rate: rate, appState: appState,
          )
        : ('—', '');

    final (inputValueStr, inputValueFiat) = btc != null
        ? formatingAmount(
            amount: btc.inputValue, symbol: symbol, decimals: decimals, rate: rate, appState: appState,
          )
        : ('0', '');

    final (outputValueStr, outputValueFiat) = btc != null
        ? formatingAmount(
            amount: btc.outputValue, symbol: symbol, decimals: decimals, rate: rate, appState: appState,
          )
        : ('0', '');

    final btcPrice = rate > 0
        ? formatingAmount(
            amount: BigInt.from(10).pow(decimals), symbol: symbol, decimals: decimals, rate: rate, appState: appState,
          ).$1
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Overview', theme: theme),
        const SizedBox(height: 8),
        _FieldRow(label: 'Hash', value: transaction.transactionHash, theme: theme, copyable: true),
        _Divider(theme: theme),
        _FieldRow(label: 'Status', value: transaction.status.name, theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Time', value: _formatTimestamp(), theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Age', value: _formatAge(), theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Inputs', value: '${btc?.input.length ?? 0}', theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Input Value', value: inputValueStr, valueFiat: inputValueFiat, theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Outputs', value: '${btc?.output.length ?? 0}', theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Output Value', value: outputValueStr, valueFiat: outputValueFiat, theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Fee', value: feeStr, valueFiat: feeFiat, theme: theme),
        _Divider(theme: theme),
        if (btc != null) ...[
          _FieldRow(label: 'Coinbase', value: btc.isCoinbase ? 'Yes' : 'No', theme: theme),
          _Divider(theme: theme),
          _FieldRow(label: 'Witness', value: btc.hasWitness ? 'Yes' : 'No', theme: theme),
          _Divider(theme: theme),
          _FieldRow(label: 'RBF', value: btc.isRbf ? 'Yes' : 'No', theme: theme),
          _Divider(theme: theme),
          _FieldRow(label: 'Locktime', value: '${btc.lockTime}', theme: theme),
          _Divider(theme: theme),
          _FieldRow(label: 'Version', value: '${btc.version}', theme: theme),
          _Divider(theme: theme),
        ],
        if (btcPrice != null)
          _FieldRow(label: 'BTC Price', value: '\$$btcPrice', theme: theme),
      ],
    );
  }

  Widget _buildFromSection(AppTheme theme) {
    final btc = transaction.btcReceipt;
    if (btc == null || btc.input.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'From', theme: theme),
        const SizedBox(height: 6),
        ...btc.input.asMap().entries.map((e) {
          final txidVout = '${e.value.previousOutput.txid}:${e.value.previousOutput.vout}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${e.key + 1}', style: theme.bodyText2.copyWith(color: theme.textSecondary.withValues(alpha: 0.5))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onLongPress: () {},
                    child: Text(txidVout, style: theme.bodyText2.copyWith(color: theme.textPrimary), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildToSection(AppState appState, AppTheme theme) {
    final btc = transaction.btcReceipt;
    if (btc == null || btc.output.isEmpty) return const SizedBox.shrink();

    final baseToken = appState.wallet?.tokens.first;
    final decimals = baseToken?.decimals ?? 8;
    final symbol = baseToken?.symbol ?? 'BTC';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'To', theme: theme),
        const SizedBox(height: 6),
        ...btc.output.asMap().entries.map((e) {
          final (formatted, _) = formatingAmount(
            amount: e.value.value, symbol: symbol, decimals: decimals, rate: 0, appState: appState,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${e.key + 1}', style: theme.bodyText2.copyWith(color: theme.textSecondary.withValues(alpha: 0.5))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(formatted, style: theme.bodyText2.copyWith(color: theme.textPrimary)),
                ),
                const SizedBox(width: 12),
                Text(symbol, style: theme.bodyText2.copyWith(color: theme.textSecondary)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNetwork(AppState appState, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Network', theme: theme),
        const SizedBox(height: 6),
        _FieldRow(label: 'Chain', value: 'BTC', theme: theme),
        _Divider(theme: theme),
        _FieldRow(label: 'Network', value: _getNetworkName(appState, transaction.chainHash), theme: theme),
      ],
    );
  }

  Widget _buildExplorerFooter(AppState appState, double pad) {
    final theme = appState.currentTheme;
    final explorers = appState.getChain(transaction.chainHash)?.explorers ?? [];
    if (explorers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: theme.modalBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: explorers
              .map((e) => _explorerBtn(e, theme))
              .toList(),
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
              ? AsyncImage(url: processUrl(explorer.icon!, theme.value), width: 22, height: 22, fit: BoxFit.contain)
              : Icon(Icons.open_in_new, size: 18, color: theme.primaryPurple),
        ),
      ),
    );
  }

  String _formatTimestamp() {
    final dt = DateTime.fromMillisecondsSinceEpoch(transaction.timestamp.toInt() * 1000);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
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

  String _getNetworkName(AppState appState, BigInt chainHash) {
    return appState.getChain(chainHash)?.chain ?? 'Unknown';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppTheme theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: theme.bodyText1.copyWith(color: theme.textPrimary, fontWeight: FontWeight.w600));
  }
}

class _Divider extends StatelessWidget {
  final AppTheme theme;
  const _Divider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: theme.modalBorder);
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? valueFiat;
  final bool copyable;
  final AppTheme theme;

  const _FieldRow({
    required this.label,
    required this.theme,
    this.value,
    this.valueFiat,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.bodyText2.copyWith(color: theme.textSecondary.withValues(alpha: 0.7))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: copyable
                ? GestureDetector(
                    onLongPress: () {},
                    child: Text(value ?? '', style: theme.bodyText2.copyWith(color: theme.primaryPurple), overflow: TextOverflow.ellipsis),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value ?? '', style: theme.bodyText2.copyWith(color: theme.textPrimary)),
                      if (valueFiat != null && valueFiat!.isNotEmpty && valueFiat != '0')
                        Text(valueFiat!, style: theme.bodyText2.copyWith(color: theme.textSecondary.withValues(alpha: 0.7))),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusAmountRow extends StatelessWidget {
  final AppTheme theme;
  final HistoricalTransactionInfo transaction;
  final AppState appState;

  const _StatusAmountRow({required this.theme, required this.transaction, required this.appState});

  @override
  Widget build(BuildContext context) {
    final (amount, fiat) = _formatAmount();
    final btc = transaction.btcReceipt;

    return Row(
      children: [
        _buildTokenIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(amount, style: theme.titleMedium.copyWith(color: theme.textPrimary)),
                  const SizedBox(width: 8),
                  _statusBadge(transaction.status, theme),
                ],
              ),
              if (fiat.isNotEmpty && fiat != '0')
                Text(fiat, style: theme.bodyText2.copyWith(color: theme.textSecondary)),
              if (btc != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${btc.input.length} input${btc.input.length > 1 ? 's' : ''} · ${btc.output.length} output${btc.output.length > 1 ? 's' : ''}',
                    style: theme.caption.copyWith(color: theme.textSecondary.withValues(alpha: 0.7)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(TransactionStatusInfo status, AppTheme theme) {
    final (color, text) = switch (status) {
      TransactionStatusInfo.pending => (Colors.orange, 'Pending'),
      TransactionStatusInfo.success => (theme.success, 'Confirmed'),
      TransactionStatusInfo.failed => (theme.danger, 'Rejected'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: theme.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTokenIcon() {
    final token = _findMatchingToken();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.primaryPurple.withValues(alpha: 0.1), width: 1.5),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: transaction.icon ??
              (token != null ? processTokenLogo(token: token, shortName: appState.chain?.shortName ?? "", theme: theme.value) : null),
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorWidget: SvgPicture.asset('assets/icons/warning.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(theme.textSecondary, BlendMode.srcIn)),
          loadingWidget: const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ),
    );
  }

  (String, String) _formatAmount() {
    final token = appState.wallet?.tokens.first;
    final amount = BigInt.tryParse(transaction.tokenInfo?.value ?? transaction.amount) ?? BigInt.zero;
    final decimals = (transaction.tokenInfo?.decimals ?? token?.decimals) ?? 1;
    final symbol = (transaction.tokenInfo?.symbol ?? token?.symbol) ?? "";
    return formatingAmount(amount: amount, symbol: symbol, decimals: decimals, rate: token?.rate ?? 0, appState: appState);
  }

  FTokenInfo? _findMatchingToken() {
    if (appState.wallet == null || transaction.tokenInfo == null || appState.account == null) return null;
    try {
      return appState.wallet!.tokens.firstWhere((t) => t.symbol == transaction.tokenInfo?.symbol && t.addrType == appState.account?.addrType);
    } catch (_) {
      return null;
    }
  }
}

Widget _dragHandle(AppTheme theme, double pad) {
  return Center(
    child: Container(
      width: 36,
      height: 4,
      margin: EdgeInsets.only(top: pad, bottom: pad / 2),
      decoration: BoxDecoration(color: theme.modalBorder, borderRadius: BorderRadius.circular(2)),
    ),
  );
}
