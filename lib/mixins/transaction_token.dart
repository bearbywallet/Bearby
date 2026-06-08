import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/state/app_state.dart';

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
    return _resolveNativeToken(tokens, transaction.chainHash);
  }

  final accountAddrType = appState.account?.addrType;

  for (final token in tokens) {
    if (_matchesToken(
      token: token,
      symbol: tokenInfo.symbol,
      chainHash: transaction.chainHash,
      addrType: accountAddrType,
    )) {
      return token;
    }
  }

  for (final token in tokens) {
    if (_matchesToken(
      token: token,
      symbol: tokenInfo.symbol,
      chainHash: null,
      addrType: accountAddrType,
    )) {
      return token;
    }
  }

  return null;
}

FTokenInfo _resolveNativeToken(List<FTokenInfo> tokens, BigInt chainHash) {
  FTokenInfo? firstNativeToken;

  for (final token in tokens) {
    if (!token.native) continue;
    firstNativeToken ??= token;
    if (token.chainHash == chainHash) return token;
  }

  return firstNativeToken ?? tokens.first;
}

bool _matchesToken({
  required FTokenInfo token,
  required String symbol,
  required BigInt? chainHash,
  required int? addrType,
}) {
  if (token.symbol != symbol) return false;
  if (chainHash != null && token.chainHash != chainHash) return false;
  if (addrType != null && token.addrType != addrType) return false;
  return true;
}
