import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/counter.dart';
import 'package:zilpay/components/smart_input.dart';
import 'dart:async';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/mixins/adaptive_size.dart';

class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _accountNameInputKey = GlobalKey<SmartInputState>();

  bool _isCreating = false;
  bool _zilliqaLegacy = false;
  String? _errorMessage;
  int _bip39Index = 0;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount(AppState appState) async {
    if (_accountNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Account name cannot be empty';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Password cannot be empty';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Here you would integrate with your Rust API for BIP39 account creation
      // await createBip39Account(
      //   name: _accountNameController.text,
      //   password: _passwordController.text,
      //   index: _bip39Index,
      // );
      // await appState.syncData(); // Sync the new account data

      await Future.delayed(const Duration(milliseconds: 1000000));
      // Navigator.pop(context); // Return to previous screen after success
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create account: $e';
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
              child: CustomAppBar(
                title: 'Add New Account',
                onBackPressed: () => Navigator.pop(context),
                actionIcon: _isCreating
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.textPrimary,
                          ),
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/icons/plus.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          theme.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                onActionPressed: () => _createAccount(appState),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: adaptivePadding,
                    right: adaptivePadding,
                    top: adaptivePadding,
                    bottom: keyboardHeight + adaptivePadding,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create BIP39 Account',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: adaptivePadding),
                        SmartInput(
                          key: _accountNameInputKey,
                          controller: _accountNameController,
                          hint: "Account name",
                          fontSize: 18,
                          height: 56,
                          disabled: _isCreating,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: theme.primaryPurple,
                        ),
                        SizedBox(height: adaptivePadding),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.secondaryPurple),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BIP39 Index',
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Counter(
                                initialValue: _bip39Index,
                                minValue: 0,
                                maxValue: 2147483647,
                                disabled: _isCreating,
                                iconColor: theme.primaryPurple,
                                numberStyle: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _bip39Index = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: adaptivePadding),
                        SmartInput(
                          key: _passwordInputKey,
                          controller: _passwordController,
                          hint: "Password",
                          fontSize: 18,
                          height: 56,
                          disabled: _isCreating,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: theme.primaryPurple,
                          obscureText: _obscurePassword,
                          rightIconPath: _obscurePassword
                              ? "assets/icons/close_eye.svg"
                              : "assets/icons/open_eye.svg",
                          onRightIconTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        SizedBox(height: adaptivePadding),
                        if (appState.chain?.slip44 == 313 &&
                            appState.wallet != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/scilla.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    theme.textPrimary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Zilliqa Legacy',
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _zilliqaLegacy,
                                  onChanged: _isCreating
                                      ? null
                                      : (bool value) async {
                                          setState(() {
                                            _zilliqaLegacy = value;
                                          });
                                        },
                                  activeColor: theme.primaryPurple,
                                  activeTrackColor: theme.primaryPurple
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        if (_errorMessage != null) ...[
                          SizedBox(height: adaptivePadding),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.danger,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
