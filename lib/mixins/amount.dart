import 'package:intl/intl.dart';
import 'package:zilpay/state/app_state.dart';

String formatAmount(BigInt amount) {
  final BigInt billion = BigInt.from(1e9);
  final BigInt million = BigInt.from(1e6);

  if (amount >= billion) {
    double result = amount.toDouble() / 1e9;
    return '${result.toStringAsFixed(2)}B';
  } else if (amount >= million) {
    double result = amount.toDouble() / 1e6;
    return '${result.toStringAsFixed(2)}M';
  } else {
    return amount.toDouble().toStringAsFixed(2);
  }
}

BigInt adjustAmount(BigInt rawBalance, int decimals) {
  // Calculate divisor (10 ** decimals)
  BigInt divisor = BigInt.from(10).pow(decimals);

  // Perform the division
  return rawBalance ~/ divisor;
}

double adjustAmountToDouble(BigInt rawBalance, int decimals) {
  // Calculate divisor (10 ** decimals)
  BigInt divisor = BigInt.from(10).pow(decimals);

  // Convert to double for decimal places
  return rawBalance.toDouble() / divisor.toDouble();
}

String formatBigNumber(double number) {
  final formatter = NumberFormat('#,##0.000', 'en_US');

  return formatter.format(number);
}

String formatCompactNumber(double value) {
  final suffixes = ['', 'K', 'M', 'B', 'T'];
  var suffixIndex = 0;

  // Find appropriate suffix
  while (value >= 1000 && suffixIndex < suffixes.length - 1) {
    value /= 1000;
    suffixIndex++;
  }

  // Format with one decimal place if there's a fraction
  if (value % 1 != 0) {
    return '${value.toStringAsFixed(1)}${suffixes[suffixIndex]}';
  } else {
    return '${value.toInt()}${suffixes[suffixIndex]}';
  }
}

String getConvertedAmount(AppState state, double amount) {
  if (state.wallet?.currencyConvert?.isEmpty ?? true) {
    return '-';
  }

  String currency = state.wallet!.currencyConvert!;
  double? converted = state.rates[currency];

  if (converted == null) {
    return '-';
  }

  return formatCompactNumber(converted * amount);
}
