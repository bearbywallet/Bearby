import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/copy_content.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/btc.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class TokenTransferInfo extends StatelessWidget {
  final TransactionRequestInfo tx;
  final BaseTokenInfo token;
  final String fromAddress;
  final String toAddress;
  final String? fromName;
  final String? toName;
  final Color? textColor;
  final Color? secondaryColor;

  const TokenTransferInfo({
    super.key,
    required this.tx,
    required this.token,
    required this.fromAddress,
    required this.toAddress,
    this.fromName,
    this.toName,
    this.textColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
    final tColor = textColor ?? theme.textPrimary;
    final sColor = secondaryColor ?? theme.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.modalBorder.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: tx.btc != null
          ? _buildBitcoin(context, state, theme, tColor, sColor)
          : _buildSingle(context, theme, tColor, sColor),
    );
  }

  Widget _buildBitcoin(
    BuildContext context,
    AppState appState,
    AppTheme theme,
    Color tColor,
    Color sColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final btc = tx.btc!.$1;
    final meta = tx.btc!.$2;
    final ins = btc.input;
    final outs = btc.output;
    final utxos = meta.witnessUtxos;

    final totalIn = utxos.fold<BigInt>(BigInt.zero, (a, u) => a + u.value);
    final totalOut = outs.fold<BigInt>(BigInt.zero, (a, o) => a + o.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFlowStrip(
            appState, theme, tColor, sColor, totalIn, totalOut, btc.fee),
        Divider(height: 1, color: theme.modalBorder.withValues(alpha: 0.3)),
        const SizedBox(height: 10),
        _buildSectionHeader(
            theme, sColor, l10n.transactionDetailsModal_from, ins.length),
        const SizedBox(height: 6),
        ...List.generate(ins.length, (i) {
          final value = i < utxos.length ? utxos[i].value : null;
          return _buildInputRow(
              appState, theme, tColor, sColor, ins[i], value);
        }),
        const SizedBox(height: 10),
        Divider(height: 1, color: theme.modalBorder.withValues(alpha: 0.3)),
        const SizedBox(height: 10),
        _buildSectionHeader(
            theme, sColor, l10n.transactionDetailsModal_to, outs.length),
        const SizedBox(height: 6),
        ...outs.map((o) => _buildOutputRow(appState, theme, tColor, sColor, o)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFlowStrip(
    AppState appState,
    AppTheme theme,
    Color tColor,
    Color sColor,
    BigInt totalIn,
    BigInt totalOut,
    BigInt? fee,
  ) {
    final inStr = _format(appState, totalIn);
    final outStr = _format(appState, totalOut);
    final feeStr = fee != null ? _format(appState, fee) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      color: theme.primaryPurple.withValues(alpha: 0.06),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _flowSide(
                theme, tColor, sColor, 'IN', inStr, CrossAxisAlignment.start),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: feeStr != null
                ? _buildFeeChip(theme, sColor, feeStr)
                : SvgPicture.asset(
                    "assets/icons/right_arrow.svg",
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                        sColor.withValues(alpha: 0.7), BlendMode.srcIn),
                  ),
          ),
          Expanded(
            child: _flowSide(
                theme, tColor, sColor, 'OUT', outStr, CrossAxisAlignment.end),
          ),
        ],
      ),
    );
  }

  Widget _flowSide(
    AppTheme theme,
    Color tColor,
    Color sColor,
    String label,
    String amount,
    CrossAxisAlignment align,
  ) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.overline.copyWith(
            color: sColor.withValues(alpha: 0.6),
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: theme.bodyText2.copyWith(
            color: tColor,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFeeChip(AppTheme theme, Color sColor, String feeStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.modalBorder.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            "assets/icons/gas.svg",
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(
                sColor.withValues(alpha: 0.85), BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            feeStr,
            style: theme.overline.copyWith(
              color: sColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      AppTheme theme, Color sColor, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.overline.copyWith(
              color: sColor.withValues(alpha: 0.7),
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.overline.copyWith(
              color: sColor.withValues(alpha: 0.7),
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    AppState appState,
    AppTheme theme,
    Color tColor,
    Color sColor,
    TxInInfo input,
    BigInt? value,
  ) {
    final addr = input.address;
    final amountStr = value != null ? _format(appState, value) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          if (addr != null) ...[
            CopyContent(address: addr, isShort: true),
            const Spacer(),
          ] else
            Expanded(
              child: Text(
                '${shortenAddress(input.previousOutput.txid)}:${input.previousOutput.vout}',
                style: theme.bodyText2.copyWith(color: sColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (amountStr != null) ...[
            const SizedBox(width: 8),
            Text(
              amountStr,
              style: theme.bodyText2.copyWith(
                color: tColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputRow(
    AppState appState,
    AppTheme theme,
    Color tColor,
    Color sColor,
    TxOutInfo output,
  ) {
    final addr = output.address;
    final isOpReturn = addr == null && output.value == BigInt.zero;
    final amountStr = _format(appState, output.value);

    final Widget addressWidget;
    if (addr != null) {
      addressWidget = CopyContent(address: addr, isShort: true);
    } else if (isOpReturn) {
      addressWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.modalBorder.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'OP_RETURN',
          style: theme.bodyText2.copyWith(
            color: sColor,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else {
      addressWidget = Text(
        '—',
        style: theme.bodyText2.copyWith(color: sColor),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          addressWidget,
          const Spacer(),
          if (!isOpReturn) ...[
            const SizedBox(width: 8),
            Text(
              amountStr,
              style: theme.bodyText2.copyWith(
                color: tColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _format(AppState appState, BigInt amount) {
    return formatingAmount(
      amount: amount,
      symbol: token.symbol,
      decimals: token.decimals,
      rate: 0,
      appState: appState,
    ).$1;
  }

  Widget _buildSingle(
    BuildContext context,
    AppTheme theme,
    Color tColor,
    Color sColor,
  ) {
    final l10n = AppLocalizations.of(context)!;

    Widget side(String? name, String address) {
      return Expanded(
        flex: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name ?? l10n.tokenTransferAmountUnknown,
              style: theme.overline.copyWith(
                color: tColor.withValues(alpha: 0.7),
                fontSize: 8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              shortenAddress(address),
              style: theme.overline.copyWith(
                color: tColor.withValues(alpha: 0.7),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          side(fromName, fromAddress),
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  "assets/icons/right_arrow.svg",
                  width: 18,
                  height: 18,
                  colorFilter:
                      ColorFilter.mode(sColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          side(toName, toAddress),
        ],
      ),
    );
  }
}
