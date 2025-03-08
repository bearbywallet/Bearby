import 'package:zilpay/src/rust/models/ftoken.dart';

enum GasFeeOption { low, market, aggressive }

BigInt calculateMaxPriorityFee(GasFeeOption option, BigInt priorityFee) {
  switch (option) {
    case GasFeeOption.low:
      return BigInt.zero;
    case GasFeeOption.market:
      final multiplied = priorityFee * BigInt.from(150);

      return multiplied ~/ BigInt.from(100);
    case GasFeeOption.aggressive:
      final multiplied = priorityFee * BigInt.from(300);

      return multiplied ~/ BigInt.from(100);
  }
}

BigInt calculateGasPrice(GasFeeOption option, BigInt gasPrice) {
  switch (option) {
    case GasFeeOption.low:
      return gasPrice;

    case GasFeeOption.market:
      final increase = gasPrice * BigInt.from(20);

      final increasedAmount = increase ~/ BigInt.from(100);
      return gasPrice + increasedAmount;

    case GasFeeOption.aggressive:
      final increase = gasPrice * BigInt.from(50);

      final increasedAmount = increase ~/ BigInt.from(100);
      return gasPrice + increasedAmount;
  }
}

BigInt calculateMaxFeePerGas(
  GasFeeOption option,
  BigInt baseFee,
  BigInt priorityFee,
) {
  final maxPriorityFee = calculateMaxPriorityFee(option, priorityFee);
  switch (option) {
    case GasFeeOption.low:
      return baseFee + maxPriorityFee;
    case GasFeeOption.market:
      return baseFee +
          maxPriorityFee +
          (baseFee * BigInt.from(20) ~/ BigInt.from(100));
    case GasFeeOption.aggressive:
      return baseFee +
          maxPriorityFee +
          (baseFee * BigInt.from(50) ~/ BigInt.from(100));
  }
}

BigInt calculateFeeForOption(
    GasFeeOption option, BigInt baseFee, BigInt priorityFee) {
  final maxPriorityFee = calculateMaxPriorityFee(option, priorityFee);
  final maxFeePerGas = calculateMaxFeePerGas(option, baseFee, priorityFee);
  final minRequired = baseFee + maxPriorityFee;

  if (maxFeePerGas < minRequired) {
    return minRequired;
  }

  return maxFeePerGas;
}

BigInt calculateEffectiveGasPrice(
  GasFeeOption option,
  BigInt baseFee,
  BigInt priorityFee,
) {
  final maxPriorityFee = calculateMaxPriorityFee(option, priorityFee);

  return maxPriorityFee + baseFee;
}

BigInt calculateTotalGasCost(
  GasFeeOption option,
  BigInt baseFee,
  BigInt priorityFee,
  BigInt gasLimit,
  BigInt gasPrice,
) {
  if (baseFee != BigInt.zero) {
    final effectiveGasPrice =
        calculateEffectiveGasPrice(option, baseFee, priorityFee);
    return effectiveGasPrice * gasLimit;
  } else {
    return calculateGasPrice(option, gasPrice) * gasLimit;
  }
}

String formatGasPriceDetail(BigInt price, FTokenInfo token) {
  final gwei = price / BigInt.from(10).pow(9);

  if (gwei < 0.1) {
    return '${price.toString()} Wei';
  } else if (gwei < 1000000) {
    return '${gwei.toStringAsFixed(2)} Gwei';
  } else {
    final eth = price / BigInt.from(10).pow(18);
    return '${eth.toStringAsFixed(6)} ${token.symbol}';
  }
}
