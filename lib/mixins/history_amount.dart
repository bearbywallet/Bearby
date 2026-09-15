import 'package:flutter/material.dart';

import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/mixins/transaction_token.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

/// Direction of a historical transfer relative to the active account.
enum TxFlow {
  incoming,
  outgoing,
  neutral,
}

/// Precomputed list/details amount payload. Built outside `build()`.
class HistoryAmountView {
  final TxFlow flow;
  /// Locale-formatted amount including symbol, without sign (e.g. `0.12 BTC`).
  final String native;
  /// Signed form for list cards (e.g. `+0.12 BTC`, `-0.12 BTC`).
  final String signedNative;
  final String fiat;
  final BigInt rawAmount;
  final String symbol;
  final TransactionStatusInfo status;

  const HistoryAmountView({
    required this.flow,
    required this.native,
    required this.signedNative,
    required this.fiat,
    required this.rawAmount,
    required this.symbol,
    required this.status,
  });

  @override
  int get hashCode => Object.hash(
        flow,
        native,
        signedNative,
        fiat,
        rawAmount,
        symbol,
        status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryAmountView &&
          runtimeType == other.runtimeType &&
          flow == other.flow &&
          native == other.native &&
          signedNative == other.signedNative &&
          fiat == other.fiat &&
          rawAmount == other.rawAmount &&
          symbol == other.symbol &&
          status == other.status;

  @override
  String toString() =>
      'HistoryAmountView(flow: $flow, signedNative: $signedNative, fiat: $fiat)';
}

bool addressesEqual(String? a, String? b) {
  if (a == null || b == null || a.isEmpty || b.isEmpty) return false;
  return a.toLowerCase() == b.toLowerCase();
}

/// Resolve send/receive direction without UI.
TxFlow resolveTxFlow({
  required HistoricalTransactionInfo transaction,
  required String? accountAddress,
}) {
  if (transaction.isSignedMessage) return TxFlow.neutral;

  final account = accountAddress;
  if (account != null && account.isNotEmpty) {
    final from = transaction.sender;
    final to = transaction.recipient;
    final fromUs = addressesEqual(from, account);
    final toUs = addressesEqual(to, account);
    if (fromUs && !toUs) return TxFlow.outgoing;
    if (toUs && !fromUs) return TxFlow.incoming;
    if (fromUs && toUs) return TxFlow.neutral;
  }

  // BTC: witness utxos (our inputs) resolve ⇒ fee/known input address ⇒ send.
  // Backfilled receives always carry broadcast=true, so broadcast is NOT a signal here.
  if (transaction.isBtcTransaction) {
    final btc = transaction.btc;
    if (btc == null) return TxFlow.neutral;
    if (btc.fee != null) return TxFlow.outgoing;
    final ownsInput = btc.input.any((i) => i.address != null);
    return ownsInput ? TxFlow.outgoing : TxFlow.incoming;
  }

  if (transaction.metadata.broadcast) return TxFlow.outgoing;

  return TxFlow.neutral;
}

/// Formats transfer amount once for history list and detail reuse.
HistoryAmountView? resolveHistoryAmount({
  required HistoricalTransactionInfo transaction,
  required AppState appState,
}) {
  if (transaction.isSignedMessage) return null;

  final token = resolveTransactionToken(
    transaction: transaction,
    appState: appState,
  );
  final baseToken = appState.wallet?.tokens.firstOrNull;

  final raw = BigInt.tryParse(
        transaction.tokenInfo?.value ?? transaction.amount,
      ) ??
      BigInt.zero;

  final decimals =
      transaction.tokenInfo?.decimals ?? token?.decimals ?? baseToken?.decimals ?? 1;
  final symbol =
      transaction.tokenInfo?.symbol ?? token?.symbol ?? baseToken?.symbol ?? '';
  final rate = token?.rate ?? baseToken?.rate ?? 0;

  final (native, fiat) = formatingAmount(
    amount: raw,
    symbol: symbol,
    decimals: decimals,
    rate: rate,
    appState: appState,
  );

  final flow = resolveTxFlow(
    transaction: transaction,
    accountAddress: appState.account?.addr,
  );

  final signedNative = switch (flow) {
    TxFlow.incoming => '+$native',
    TxFlow.outgoing => '-$native',
    TxFlow.neutral => native,
  };

  return HistoryAmountView(
    flow: flow,
    native: native,
    signedNative: signedNative,
    fiat: fiat,
    rawAmount: raw,
    symbol: symbol,
    status: transaction.status,
  );
}

Color historyAmountColor({
  required TxFlow flow,
  required TransactionStatusInfo status,
  required AppTheme theme,
}) {
  if (status == TransactionStatusInfo.failed) return theme.danger;
  return switch (flow) {
    TxFlow.incoming => theme.success,
    TxFlow.outgoing => theme.textPrimary,
    TxFlow.neutral => theme.textPrimary,
  };
}
