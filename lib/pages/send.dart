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
import 'package:zilpay/modals/sign_tx.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/src/rust/models/transactions/evm.dart';
import 'package:zilpay/state/app_state.dart';

class SendTokenPage extends StatefulWidget {
  const SendTokenPage({super.key});

  @override
  State<SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<SendTokenPage> {
  bool _initialized = false;
  int tokenIndex = 0;
  String amount = "0";
  String convertAmount = "0";
  bool hasDecimalPoint = false;
  String? address;
  String? walletName;

  late final AppState _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final int? argTokenIndex = args?['token_index'];

      if (argTokenIndex != null) {
        setState(() {
          tokenIndex = argTokenIndex;
        });
      }
      _initialized = true;
    }
  }

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
      final balance = adjustAmountToDouble(bigBalance, token.decimals);

      return numAmount >= 0 && numAmount <= balance;
    } catch (e) {
      debugPrint("amount is not valid $e");
      return false;
    }
  }

  bool get isValidAddress {
    if (address == null || address!.isEmpty) {
      return false;
    }

    return true;
  }

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

  void updateAddress(QRcodeScanResultInfo params, String name) {
    setState(() {
      if (params.recipient.isNotEmpty) {
        address = params.recipient;
      }

      if (params.amount != null && params.amount!.isNotEmpty) {
        amount = params.amount!;
      }

      // TODO: check token address if exits in
      // if we have token in stash so we can swap to other token

      walletName = name;
    });
  }

  void handleKeyPress(String value) {
    if (value == ".") {
      if (!hasDecimalPoint) {
        setState(() {
          hasDecimalPoint = true;
          if (amount == "0") {
            amount = "0.";
          } else {
            amount += value;
          }
        });
      }
      return;
    }

    setState(() {
      if (hasDecimalPoint) {
        amount += value;
      } else {
        if (amount == "0") {
          amount = value;
        } else {
          amount += value;
        }
      }
    });
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

  void _showSimpleTransfer(BuildContext context) {
    // Simple ETH transfer transaction
    final transaction = TransactionRequestEVM(
      from: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
      to: '0x123456789abcdef123456789abcdef123456789a',
      value: '1000000000000000000', // 1 ETH in wei
      gasLimit: BigInt.from(21000),
      gasPrice: BigInt.from(20000000000), // 20 Gwei
      nonce: BigInt.from(0),
      chainId: BigInt.from(1), // Ethereum mainnet
    );

    showSignParamsModal(
      context: context,
      transactions: [transaction],
      onConfirm: (transactions) {
        final confirmedTx = transactions.first;
        print('Confirmed transaction with gas limit: ${confirmedTx.gasLimit}');
        // Handle transaction signing and sending
      },
    );
  }

  void handleSubmit() {
    if (isFormValid) {
      // _showSimpleTransfer();
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
                              onPressed: () => _showSimpleTransfer(context),
                              // onPressed: handleSubmit,
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
