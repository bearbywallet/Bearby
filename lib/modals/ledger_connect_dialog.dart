import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zilpay/components/counter.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';

class LedgerConnectDialog extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onConnect;

  const LedgerConnectDialog({
    super.key,
    this.onClose,
    this.onConnect,
  });

  @override
  State<LedgerConnectDialog> createState() => _LedgerConnectDialog();
}

class _LedgerConnectDialog extends State<LedgerConnectDialog> {
  static const defaultName = "Ledger";
  final _btnController = RoundedLoadingButtonController();
  final _walletNameController = TextEditingController();

  bool _isKeyboardVisible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _walletNameController.text = '$defaultName 0';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Wrap(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Ledger 1',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: SvgPicture.asset(
                            'assets/icons/close.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              theme.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SmartInput(
                      controller: _walletNameController,
                      hint: "Wallet Name",
                      fontSize: 18,
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      focusedBorderColor: theme.primaryPurple,
                      disabled: _loading,
                      onFocusChanged: (isFocused) {
                        setState(() {
                          _isKeyboardVisible = isFocused;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    Counter(
                      iconSize: 32,
                      iconColor: theme.textPrimary,
                      animationDuration: const Duration(milliseconds: 300),
                      numberStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                      initialValue: 0,
                      onChanged: (value) {
                        _walletNameController.text = "$defaultName $value";
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: RoundedLoadingButton(
                        controller: _btnController,
                        onPressed: widget.onConnect,
                        successIcon: SvgPicture.asset(
                          'assets/icons/ok.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            theme.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        child: Text(
                          'Connect',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
