import 'package:flutter/foundation.dart';

import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/state/app_state.dart';

FTokenInfo? resolveTransactionIconToken({
  required HistoricalTransactionInfo transaction,
  required AppState appState,
}) {
  if (transaction.isBtcTransaction) {
    return _resolveChainNativeToken(
      transaction: transaction,
      appState: appState,
      debugReason: 'btc icon native miss',
    );
  }

  return resolveTransactionToken(
    transaction: transaction,
    appState: appState,
  );
}

FTokenInfo? resolveTransactionToken({
  required HistoricalTransactionInfo transaction,
  required AppState appState,
}) {
  final wallet = appState.wallet;
  if (wallet == null) return null;

  final tokens = wallet.tokens;
  if (tokens.isEmpty) return null;

  final tokenInfo = transaction.tokenInfo;
  if (tokenInfo == null) {
    return _resolveNativeToken(tokens, transaction.chainHash, transaction);
  }

  final chainSymbolMatch = tokens.where((token) {
    return token.chainHash == transaction.chainHash &&
        token.symbol == tokenInfo.symbol;
  }).firstOrNull;
  if (chainSymbolMatch != null) return chainSymbolMatch;

  final chainNativeMatch = tokens.where((token) {
    return token.chainHash == transaction.chainHash && token.native;
  }).firstOrNull;
  if (chainNativeMatch != null && chainNativeMatch.symbol == tokenInfo.symbol) {
    return chainNativeMatch;
  }

  final symbolMatch = tokens.where((token) {
    return token.symbol == tokenInfo.symbol;
  }).firstOrNull;
  if (symbolMatch != null) {
    _debugTokenFallback(transaction, 'symbol-only match=${symbolMatch.symbol}');
    return symbolMatch;
  }

  return null;
}

FTokenInfo? _resolveChainNativeToken({
  required HistoricalTransactionInfo transaction,
  required AppState appState,
  required String debugReason,
}) {
  final wallet = appState.wallet;
  if (wallet == null || wallet.tokens.isEmpty) return null;

  final token = wallet.tokens.where((token) {
    return token.chainHash == transaction.chainHash && token.native;
  }).firstOrNull;
  if (token != null) return token;

  _debugTokenFallback(transaction, debugReason);
  return null;
}

FTokenInfo _resolveNativeToken(
  List<FTokenInfo> tokens,
  BigInt chainHash,
  HistoricalTransactionInfo transaction,
) {
  final chainNativeToken = tokens.where((token) {
    return token.chainHash == chainHash && token.native;
  }).firstOrNull;
  if (chainNativeToken != null) return chainNativeToken;

  final firstNativeToken = tokens.where((token) => token.native).firstOrNull;
  if (firstNativeToken != null) {
    _debugTokenFallback(
      transaction,
      'native chain miss, fallback=${firstNativeToken.symbol}',
    );
    return firstNativeToken;
  }

  _debugTokenFallback(transaction, 'native miss, fallback=tokens.first');
  return tokens.first;
}

void _debugTokenFallback(
  HistoricalTransactionInfo transaction,
  String reason,
) {
  debugPrint(
    '[HistoryToken] fallback reason=$reason '
    'hash=${transaction.transactionHash} '
    'chainHash=${transaction.chainHash} '
    'chainType=${transaction.chainType} '
    'tokenSymbol=${transaction.tokenInfo?.symbol} '
    'tokenValue=${transaction.tokenInfo?.value} '
    'metadataIcon=${transaction.icon}',
  );
}
