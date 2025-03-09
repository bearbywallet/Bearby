import 'dart:math';

import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/state/app_state.dart';

double adjustAmountToDouble(BigInt rawBalance, int decimals) {
  if (rawBalance == BigInt.zero) {
    return 0;
  }

  BigInt divisor = BigInt.from(10).pow(decimals);

  return rawBalance.toDouble() / divisor.toDouble();
}

BigInt toWei(String amount, int decimals) {
  return BigInt.from(double.parse(amount) * pow(10, decimals));
}

(String, String) formatingAmount({
  required BigInt amount,
  required String symbol,
  required int decimals,
  required double rate,
  required AppState appState,
}) {
  String? convertedSymbolStr = appState.wallet?.settings.currencyConvert;

  return intlNumberFormating(
    value: amount.toString(),
    decimals: decimals,
    localeStr: appState.state.locale,
    nativeSymbolStr: symbol,
    convertedSymbolStr: convertedSymbolStr ?? '',
    threshold: baseThreshold,
    compact: appState.state.abbreviatedNumber,
    converted: rate,
  );
}
