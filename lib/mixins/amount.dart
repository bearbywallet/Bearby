import 'dart:math';

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
