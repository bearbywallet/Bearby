import 'dart:async';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/counter.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> with StatusBarMixin {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _accountNameInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  bool _isCreating = false;
  bool _zilliqaLegacy = false;
  String? _errorMessage;
  int _bip39Index = 0;
  bool _obscurePassword = true;
  bool _useBiometrics = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    AppState appState = Provider.of<AppState>(context, listen: false);
    _bip39Index = appState.accounts.length;
    _checkBiometricAvailability(appState);

    if (appState.account?.addrType == kScillaAddressType) {
      _zilliqaLegacy = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      AppState appState = Provider.of<AppState>(context, listen: false);
      _setAutoAccountName(appState);
      _initialized = true;
    }
  }

  void _checkBiometricAvailability(AppState appState) {
    if (appState.wallet != null) {
      final authType = appState.wallet!.authType;
      setState(() {
        _useBiometrics = authType != "none";
      });
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setAutoAccountName(AppState appState) {
    _accountNameController.text = AppLocalizations.of(
      context,
    )!
        .addAccountPageDefaultName(_bip39Index);
  }

  bool _exists(AppState appState) {
    return appState.accounts.any(
      (account) => account.index.toInt() == _bip39Index,
    );
  }

  bool _isZIL(AppState appState) {
    if (appState.wallet == null) {
      return false;
    }

    if (appState.chain == null) {
      return false;
    }

    return appState.chain?.slip44 == kZilliqaSlip44 &&
        appState.wallet != null &&
        appState.chain?.slip44 == appState.wallet?.slip44;
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _createAccount(AppState appState) async {
    final l10n = AppLocalizations.of(context)!;
    BigInt walletIndex = appState.selectedWalletIndex;

    if (_exists(appState)) {
      setState(() {
        _errorMessage = l10n.addAccountPageIndexExists(_bip39Index);
      });
      return;
    }

    if (_accountNameController.text.isEmpty) {
      _accountNameInputKey.currentState?.shake();
      return;
    }

    if (_passwordController.text.isEmpty &&
        appState.wallet!.authType == "none" &&
        !_useBiometrics) {
      _passwordInputKey.currentState?.shake();
      return;
    }

    _btnController.start();
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final wallet = appState.wallet!;
      final isSecretPhrase =
          wallet.walletType.contains(WalletType.SecretPhrase.name);

      if (isSecretPhrase) {
        AddNextBip39AccountParams params = AddNextBip39AccountParams(
          walletIndex: walletIndex,
          accountIndex: BigInt.from(_bip39Index),
          name: _accountNameController.text,
          passphrase: "",
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
        );

        await addNextBip39Account(
          params: params,
        );
      }

      await appState.syncData();
      final afterIndexes =
          appState.accounts.map((a) => a.index.toInt()).toList();

      if (isSecretPhrase && !afterIndexes.contains(_bip39Index)) {
        if (kDebugMode) {
          debugPrint(
            '[add-account] sync_missing_account index=$_bip39Index',
          );
        }
        _btnController.reset();
        setState(() {
          _errorMessage = l10n.addAccountPageCreateFailed(
              'account $_bip39Index not visible after sync');
          _isCreating = false;
        });
        return;
      }

      if (_zilliqaLegacy && _isZIL(appState) && appState.wallet != null) {
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: BigInt.from(appState.accounts.length - 1),
        );
      }

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'add account failed walletIndex=$walletIndex '
          'bip39Index=$_bip39Index error=$e\n$st',
        );
      }
      _btnController.reset();
      setState(() {
        _errorMessage = l10n.addAccountPageCreateFailed(e);
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;
    final showPassword = appState.wallet?.authType == "none";

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
              child: Column(
                children: [
                  CustomAppBar(
                    title: l10n.addAccountPageTitle,
                    onBackPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: adaptivePadding),
                          SmartInput(
                            key: _accountNameInputKey,
                            controller: _accountNameController,
                            hint: l10n.addAccountPageNameHint,
                            fontSize: 18,
                            height: 56,
                            disabled: _isCreating,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            focusedBorderColor: theme.primaryPurple,
                            onChanged: (_) => _clearError(),
                          ),
                          if (showPassword) ...[
                            SizedBox(height: adaptivePadding),
                            SmartInput(
                              key: _passwordInputKey,
                              controller: _passwordController,
                              hint: l10n.addAccountPagePasswordHint,
                              fontSize: 18,
                              height: 56,
                              disabled: _isCreating,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              focusedBorderColor: theme.primaryPurple,
                              obscureText: _obscurePassword,
                              rightIcon: AppIconState.passwordVisibility(
                                  obscured: _obscurePassword),
                              onRightIconTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              onChanged: (_) => _clearError(),
                              onSubmitted: (_) => _createAccount(appState),
                            ),
                          ],
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
                                  l10n.addAccountPageBip39Index,
                                  style: theme.bodyLarge.copyWith(
                                    color: theme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Counter(
                                  initialValue: _bip39Index,
                                  minValue: 0,
                                  maxValue: 2147483647,
                                  disabled: _isCreating,
                                  iconColor: theme.primaryPurple,
                                  numberStyle: theme.bodyLarge.copyWith(
                                    color: theme.textPrimary,
                                  ),
                                  errorText: _exists(appState)
                                      ? l10n.addAccountPageIndexExists(
                                          _bip39Index)
                                      : null,
                                  onChanged: (value) {
                                    setState(() {
                                      _bip39Index = value;
                                      _errorMessage = null;
                                    });
                                    _setAutoAccountName(appState);
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_isZIL(appState)) ...[
                            SizedBox(height: adaptivePadding),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
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
                                      l10n.addAccountPageZilliqaLegacy,
                                      style: theme.bodyLarge.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.w500,
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
                                    activeThumbColor: theme.primaryPurple,
                                    activeTrackColor: theme.primaryPurple
                                        .withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            SizedBox(height: adaptivePadding),
                            GlassMessage(
                              message: _errorMessage!,
                              type: GlassMessageType.error,
                              onDismiss: () =>
                                  setState(() => _errorMessage = null),
                            ),
                          ],
                          SizedBox(height: adaptivePadding),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: adaptivePadding),
                    child: RoundedLoadingButton(
                      color: theme.primaryPurple,
                      valueColor: theme.buttonText,
                      controller: _btnController,
                      onPressed:
                          _isCreating ? null : () => _createAccount(appState),
                      child: Text(
                        l10n.addAccountPageCreateButton,
                        style: theme.titleSmall.copyWith(
                          color: theme.buttonText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
