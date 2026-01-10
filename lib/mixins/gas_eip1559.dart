import 'package:zilpay/config/web3_constants.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';

enum GasFeeOption { low, market, aggressive }

BigInt calculateMaxPriorityFee(GasFeeOption option, BigInt priorityFee) {
  switch (option) {
    case GasFeeOption.low:
      final multiplied = priorityFee * BigInt.from(kGasPriceMultiplierLow);
      return multiplied ~/ BigInt.from(100);
    case GasFeeOption.market:
      final multiplied = priorityFee * BigInt.from(kGasPriceMultiplierMarket);
      return multiplied ~/ BigInt.from(100);
    case GasFeeOption.aggressive:
      final multiplied =
          priorityFee * BigInt.from(kGasPriceMultiplierAggressive);
      return multiplied ~/ BigInt.from(100);
  }
}

BigInt calculateGasPrice(GasFeeOption option, BigInt gasPrice) {
  switch (option) {
    case GasFeeOption.low:
      final multiplied = gasPrice * BigInt.from(kGasPriceMultiplierLow);
      return multiplied ~/ BigInt.from(100);

    case GasFeeOption.market:
      final multiplied = gasPrice * BigInt.from(kGasPriceMultiplierMarket);
      return multiplied ~/ BigInt.from(100);

    case GasFeeOption.aggressive:
      final multiplied = gasPrice * BigInt.from(kGasPriceMultiplierAggressive);
      return multiplied ~/ BigInt.from(100);
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
      final baseBuffer = baseFee * BigInt.from(125) ~/ BigInt.from(100);
      return baseBuffer + maxPriorityFee;
    case GasFeeOption.market:
      final baseBuffer = baseFee * BigInt.from(150) ~/ BigInt.from(100);
      return baseBuffer + maxPriorityFee;
    case GasFeeOption.aggressive:
      final baseBuffer = baseFee * BigInt.from(200) ~/ BigInt.from(100);
      return baseBuffer + maxPriorityFee;
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
