import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';

class TransactionAmountDisplay extends StatelessWidget {
  final BigInt amount;
  final BigInt fee;
  final FTokenInfo token;
  final BigInt balance;
  final Color textColor;

  const TransactionAmountDisplay({
    super.key,
    required this.amount,
    required this.fee,
    required this.token,
    required this.balance,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: _buildAmountDisplay(context),
      );
    });
  }

  Widget _buildAmountDisplay(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final nativeToken = appState.wallet?.tokens.first;
    final bool isNative = token.native;
    final bool isMaxTransfer = isNative && amount == balance;

    final TextStyle amountStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textColor,
    );

    final TextStyle feeStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: textColor.withValues(alpha: 0.8),
    );

    final TextStyle conversionAmountStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textColor.withValues(alpha: 0.6),
    );

    final TextStyle conversionFeeStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: textColor.withValues(alpha: 0.6),
    );

    String amountText;
    String? feeText;
    String? amountConversion;
    String? feeConversion;
    String connector = "";

    if (isMaxTransfer) {
      final adjustedAmount = amount - fee;
      final (normalizedAmount, convertedAmount) = formatingAmount(
        amount: adjustedAmount,
        symbol: token.symbol,
        decimals: token.decimals,
        rate: token.rate,
        appState: appState,
      );
      amountText = normalizedAmount;
      amountConversion = convertedAmount;
      connector = " - ";
    } else {
      final (normalizedAmount, convertedAmount) = formatingAmount(
        amount: amount,
        symbol: token.symbol,
        decimals: token.decimals,
        rate: token.rate,
        appState: appState,
      );
      amountText = normalizedAmount;
      amountConversion = convertedAmount;
      connector = " + ";
    }

    if (nativeToken?.native == true) {
      final (normalizedFee, convertedFee) = formatingAmount(
        amount: fee,
        symbol: nativeToken!.symbol,
        decimals: nativeToken.decimals,
        rate: nativeToken.rate,
        appState: appState,
      );
      feeText = normalizedFee;
      feeConversion = convertedFee;
    }

    final bool hasConversion =
        appState.wallet?.settings.currencyConvert != null &&
            (!amountConversion.contains('-')) &&
            (feeConversion == null || !feeConversion.contains('-'));

    return Column(
      children: [
        feeText != null
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(amountText,
                        style: amountStyle, overflow: TextOverflow.ellipsis),
                    Text(connector, style: amountStyle),
                    Text(feeText,
                        style: feeStyle, overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            : Text(
                amountText,
                style: amountStyle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
        if (hasConversion)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: feeText != null && feeConversion != null
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(amountConversion,
                            style: conversionAmountStyle,
                            overflow: TextOverflow.ellipsis),
                        Text(connector, style: conversionAmountStyle),
                        Text(feeConversion,
                            style: conversionFeeStyle,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                : Text(
                    amountConversion,
                    style: conversionAmountStyle,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
      ],
    );
  }
}
