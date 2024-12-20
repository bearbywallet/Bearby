import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/input_amount.dart';
import 'package:zilpay/components/number_keyboard.dart';
import 'package:zilpay/components/wallet_selector_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/state/app_state.dart';

class SendTokenPage extends StatefulWidget {
  const SendTokenPage({super.key});

  @override
  State<SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<SendTokenPage> {
  int tokenIndex = 0;
  String amount = "0";
  String convertAmount = "0";
  bool hasDecimalPoint = false;
  String? address;
  String? walletName;

  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
  }

  bool get isValidAmount {
    if (amount.endsWith('.')) {
      return false;
    }

    try {
      final numAmount = double.parse(amount);
      final token = _appState.wallet!.tokens[tokenIndex];
      final bigBalance = BigInt.parse(
          token.balances[_appState.wallet!.selectedAccount] ?? '0');
      final balance = adjustBalanceToDouble(bigBalance, token.decimals);

      return numAmount > 0 && numAmount <= balance;
    } catch (e) {
      debugPrint("amoutn is not valid $e");
      return false;
    }
  }

  bool get isValidAddress {
    if (address == null || address!.isEmpty) {
      return false;
    }

    return true;
  }

  // Combined validation for submit button
  bool get isFormValid => isValidAmount && isValidAddress;

  void updateAmount(String value) {
    setState(() {
      if (amount == "0" && value != ".") {
        amount = value;
      } else {
        amount += value;
      }
    });
  }

  void updateAddress(String value, String name) {
    setState(() {
      address = value;
      walletName = name;
    });
  }

  void handleKeyPress(String value) {
    if (value == ".") {
      if (!hasDecimalPoint) {
        setState(() {
          hasDecimalPoint = true;
          updateAmount(value);
        });
      }
    } else {
      int decimalIndex = amount.indexOf('.');
      int wholeNumberLength = decimalIndex == -1 ? amount.length : decimalIndex;

      if (decimalIndex != -1 && amount.length - decimalIndex > 2) {
        return;
      }

      if (wholeNumberLength < 8) {
        updateAmount(value);
      }
    }
  }

  void handleBackspace() {
    setState(() {
      if (amount.length > 1) {
        if (amount[amount.length - 1] == '.') {
          hasDecimalPoint = false;
        }
        amount = amount.substring(0, amount.length - 1);
      } else {
        amount = "0";
        hasDecimalPoint = false;
      }
    });
  }

  void handleSubmit() {
    if (isFormValid) {
      // Implement your submit logic here
      print('Submitting with amount: $amount and address: $address');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: '',
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      physics: const BouncingScrollPhysics(),
                      overscroll: true,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            TokenAmountCard(
                              amount: amount,
                              convertAmount: convertAmount,
                              tokenIndex: tokenIndex,
                              onMaxTap: (String value) {
                                setState(() {
                                  amount = value;
                                });
                              },
                              onTokenSelected: (int value) {
                                setState(() {
                                  tokenIndex = value;
                                  amount = '0';
                                });
                              },
                            ),
                            SvgPicture.asset(
                              "assets/icons/down_arrow.svg",
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary.withOpacity(0.1),
                                BlendMode.srcIn,
                              ),
                            ),
                            WalletSelectionCard(
                              address: address,
                              walletName: walletName,
                              onChange: updateAddress,
                            ),
                            NumberKeyboard(
                              onKeyPressed: (value) {
                                handleKeyPress(value.toString());
                              },
                              onBackspace: handleBackspace,
                              onDotPress: () => handleKeyPress("."),
                            ),
                            CustomButton(
                              text: "Submit",
                              onPressed: handleSubmit,
                              disabled: !isFormValid,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
