import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/input_amount.dart';
import 'package:zilpay/components/number_keyboard.dart';
import 'package:zilpay/components/wallet_selector_card.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';

class SendTokenPage extends StatefulWidget {
  const SendTokenPage({super.key});

  @override
  State<SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<SendTokenPage> {
  String amount = "0";
  String convertAmount = "0";
  bool hasDecimalPoint = false;

  void updateAmount(String value) {
    setState(() {
      if (amount == "0" && value != ".") {
        amount = value;
      } else {
        amount += value;
      }
      // Here you can add logic to calculate convertAmount based on exchange rates
      convertAmount = amount; // Placeholder conversion
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
      // Prevent more than 8 digits before decimal point
      int decimalIndex = amount.indexOf('.');
      int wholeNumberLength = decimalIndex == -1 ? amount.length : decimalIndex;

      // Prevent more than 2 digits after decimal point
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
      convertAmount = amount; // Update conversion
    });
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
                              initialTokenIndex: 0,
                              onMaxTap: () {
                                // Implement max amount logic here
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
                              walletName: 'My Wallet',
                              transferCount: 5,
                              address: '0x123...',
                              onTap: () {
                                debugPrint("clicked");
                              },
                            ),
                            NumberKeyboard(
                              onKeyPressed: (value) {
                                handleKeyPress(value.toString());
                              },
                              onBackspace: handleBackspace,
                              onDotPress: () => handleKeyPress("."),
                            ),
                            const SizedBox(height: 8),
                            CustomButton(
                              text: "submit",
                              onPressed: () {
                                // Implement submit logic
                              },
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
