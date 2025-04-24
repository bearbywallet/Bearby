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
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class SendTokenPage extends StatefulWidget {
  const SendTokenPage({super.key});

  @override
  State<SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<SendTokenPage> {
  bool _initialized = false;
  int _tokenIndex = 0;
  String _amount = "0";
  bool _hasDecimalPoint = false;
  String? _address;
  String? _walletName;

  late final AppState _appState;

  bool get _isFormValid => _isValidAmount && _isValidAddress;

  bool get _isValidAddress {
    if (_address == null || _address!.isEmpty) {
      return false;
    }

    return true;
  }

  bool get _isValidAmount {
    if (_amount.endsWith('.')) {
      return false;
    }

    try {
      final numAmount = double.parse(_amount);
      final token = _appState.wallet!.tokens[_tokenIndex];
      final bigBalance = BigInt.parse(
          token.balances[_appState.wallet!.selectedAccount] ?? '0');
      final balance =
          fromWei(value: bigBalance.toString(), decimals: token.decimals);

      return numAmount >= 0 && numAmount <= double.parse(balance);
    } catch (e) {
      debugPrint("amount is not valid $e");
      return false;
    }
  }

  void _updateValue(String value) {
    setState(() {
      _amount = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

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
                    title: l10n.sendTokenPageTitle,
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
                              amount: _amount,
                              tokenIndex: _tokenIndex,
                              onMaxTap: _updateValue,
                              onTokenSelected: (int value) {
                                setState(() {
                                  _tokenIndex = value;
                                  _amount = '0';
                                });
                              },
                            ),
                            SvgPicture.asset(
                              "assets/icons/down_arrow.svg",
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                theme.textSecondary.withValues(alpha: 0.1),
                                BlendMode.srcIn,
                              ),
                            ),
                            WalletSelectionCard(
                              address: _address,
                              walletName: _walletName,
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
                              textColor: theme.buttonText,
                              backgroundColor: theme.primaryPurple,
                              text: l10n.sendTokenPageSubmitButton,
                              onPressed: () => handleSubmit(appState),
                              disabled: !_isFormValid,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final int? argTokenIndex = args?['token_index'];

      if (argTokenIndex != null) {
        setState(() {
          _tokenIndex = argTokenIndex;
        });
      }
      _initialized = true;
    }
  }

  void handleBackspace() {
    setState(() {
      if (_amount.length > 1) {
        if (_amount[_amount.length - 1] == '.') {
          _hasDecimalPoint = false;
        }
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = "0";
        _hasDecimalPoint = false;
      }
    });
  }

  void handleKeyPress(String value) {
    if (value == ".") {
      if (!_hasDecimalPoint) {
        setState(() {
          _hasDecimalPoint = true;
          if (_amount == "0") {
            _amount = "0.";
          } else {
            _amount += value;
          }
        });
      }
      return;
    }

    setState(() {
      if (_hasDecimalPoint) {
        _amount += value;
      } else {
        if (_amount == "0") {
          _amount = value;
        } else {
          _amount += value;
        }
      }
    });
  }

  void handleSubmit(AppState appState) async {
    if (!_isFormValid) {
      return;
    }

    try {
      BigInt accountIndex = appState.wallet!.selectedAccount;
      FTokenInfo token = appState.wallet!.tokens[_tokenIndex];
      TokenTransferParamsInfo params = TokenTransferParamsInfo(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: accountIndex,
        token: token,
        amount: toDecimalsWei(_amount, token.decimals).toString(),
        recipient: _address ?? "",
        icon: processTokenLogo(
          token: token,
          shortName: appState.chain?.shortName ?? '',
          theme: appState.currentTheme.value,
        ),
      );

      TransactionRequestInfo tx = await createTokenTransfer(params: params);
      if (!mounted) return;
      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: _address!,
        token: token,
        amount: _amount,
        onConfirm: (_) {
          Navigator.of(context).pushNamed('/', arguments: {
            'selectedIndex': 1,
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: appState.currentTheme.cardBackground,
          title: Text(
            "Error",
            style: TextStyle(color: appState.currentTheme.textPrimary),
          ),
          content: Text(
            errorMessage,
            style: TextStyle(color: appState.currentTheme.danger),
          ),
          actions: [],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
  }

  void updateAddress(QRcodeScanResultInfo params, String name) {
    setState(() {
      if (params.recipient.isNotEmpty) {
        _address = params.recipient;
      }

      if (params.amount != null && params.amount!.isNotEmpty) {
        _amount = params.amount!;
      }

      _walletName = name;
    });

    Navigator.pop(context);
  }

  void updateAmount(String value) {
    setState(() {
      if (_amount == "0" && value != ".") {
        _amount = value;
      } else {
        _amount += value;
      }
    });
  }
}
