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

class SendTokenPage extends StatelessWidget {
  const SendTokenPage({super.key});

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
                            const SizedBox(
                              height: 16,
                            ),
                            TokenAmountCard(
                              amount: "0",
                              convertAmount: "0",
                              tokenIndex: 0,
                              onMaxTap: () {},
                            ),
                            SvgPicture.asset(
                              "assets/icons/down_arrow.svg",
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary.withOpacity(0.2),
                                BlendMode.srcIn,
                              ),
                            ),
                            WalletSelectionCard(
                              walletName: 'My Wallet',
                              transferCount: 5,
                              address: '0x123...',
                              onTap: () {
                                debugPrint("clicked");
                                // Your tap handler
                              },
                            ),
                            NumberKeyboard(
                              onKeyPressed: (value) {
                                debugPrint("value $value");
                              },
                              onBackspace: () {
                                debugPrint("remove");
                              },
                              onDotPress: () {
                                debugPrint(".");
                              },
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            CustomButton(
                              text: "submit",
                              onPressed: () {},
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
