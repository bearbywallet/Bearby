import 'package:zilpay/src/rust/models/ftoken.dart';

enum GasFeeOption { low, market, aggressive }

BigInt calculateMaxPriorityFee(GasFeeOption option, BigInt priorityFee) {
  switch (option) {
    case GasFeeOption.low:
      return BigInt.zero;
    case GasFeeOption.market:
      return priorityFee * BigInt.from(150) ~/ BigInt.from(100);
    case GasFeeOption.aggressive:
      return priorityFee * BigInt.from(300) ~/ BigInt.from(100);
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
    GasFeeOption option, BigInt baseFee, BigInt priorityFee) {
  final maxPriorityFee = calculateMaxPriorityFee(option, priorityFee);
  final maxFeePerGas = calculateMaxFeePerGas(option, baseFee, priorityFee);

  final availablePriorityFee = maxFeePerGas - baseFee;

  final effectivePriorityFee = maxPriorityFee < availablePriorityFee
      ? maxPriorityFee
      : availablePriorityFee;

  return baseFee + effectivePriorityFee;
}

BigInt calculateTotalGasCost(
    GasFeeOption option, BigInt baseFee, BigInt priorityFee, BigInt gasLimit) {
  final effectiveGasPrice =
      calculateEffectiveGasPrice(option, baseFee, priorityFee);
  return effectiveGasPrice * gasLimit;
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

String formatGasPrice(BigInt price, int decimals, String symbol) {
  final value = price / BigInt.from(10).pow(decimals);
  return '${value.toStringAsFixed(5)} $symbol';
}
