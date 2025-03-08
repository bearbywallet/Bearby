import 'dart:math';

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

double adjustAmountToDouble(BigInt rawBalance, int decimals) {
  if (rawBalance == BigInt.zero) {
    return 0;
  }
  // Calculate divisor (10 ** decimals)
  BigInt divisor = BigInt.from(10).pow(decimals);

  // Convert to double for decimal places
  return rawBalance.toDouble() / divisor.toDouble();
}

BigInt toWei(String amount, int decimals) {
  return BigInt.from(double.parse(amount) * pow(10, decimals));
}
