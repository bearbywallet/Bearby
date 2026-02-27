import 'package:flutter/rendering.dart';
import 'package:bearby/config/ftokens.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/state/app_state.dart';

BigInt toDecimalsWei(String amount, int decimals) {
  try {
    final (value, dec) = toWei(value: amount, decimals: decimals);

    return BigInt.parse(value);
  } catch (e) {
    debugPrint("fail to parse number $amount");

    return BigInt.zero;
  }
}

(String, String) formatingAmount({
  required BigInt amount,
  required String symbol,
  required int decimals,
  required double rate,
  required AppState appState,
  double? threshold,
  bool? compact,
}) {
  String? convertedSymbolStr = appState.wallet?.settings.currencyConvert;
  double converted = 0;

  if (appState.account != null &&
      appState.wallet?.settings.ratesApiOptions != 0) {
    final account = appState.account;
    final chain = appState.getChain(account!.chainHash);

    converted = chain?.testnet == true ? 0 : rate;
  }

  return intlNumberFormating(
    value: amount.toString(),
    decimals: decimals,
    localeStr: appState.state.locale ?? "",
    nativeSymbolStr: symbol,
    convertedSymbolStr: convertedSymbolStr ?? '',
    threshold: threshold ?? baseThreshold,
    compact: compact ?? appState.state.abbreviatedNumber,
    converted: converted,
  );
}
