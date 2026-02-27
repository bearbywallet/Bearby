import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bearby/components/biometric_switch.dart';
import 'package:bearby/components/bip_purpose_selector.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/config/argon.dart';
import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/config/cipher.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/encryption_settings.dart';
import 'package:bearby/src/rust/api/auth.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/keypair.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/settings.dart';
import 'package:bearby/state/app_state.dart' show AppState;
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/utils/utils.dart';

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage>
    with StatusBarMixin {
  List<String>? _bip39List;
  NetworkConfigInfo? _chain;
  KeyPairInfo? _keys;
  int _selectedPurposeIndex = 0; // Default to BIP86 (Taproot)
  int _selectedCipherIndex = CipherDefaults.defaultCipherIndex;
  WalletArgonParamsInfo _argonParams = Argon2DefaultParams.owaspDefault();

  late AppState _appState;

  List<String> _authMethods = [];
  bool _useDeviceAuth = true;
  bool _zilLegacy = false;
  bool _bypassChecksumValidation = false;

  String? _errorMessage;
  bool _disabled = false;
  bool _walletNameInitialized = false;
  bool _updatedArgs = false;

  final _btnController = RoundedLoadingButtonController();

  final _walletNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _confirmPasswordInputKey = GlobalKey<SmartInputState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_updatedArgs) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final chain = args?['chain'] as NetworkConfigInfo?;
    final keys = args?['keys'] as KeyPairInfo?;
    final bypassChecksumValidation = args?['ignore_checksum'] as bool?;

    if (bip39 == null && chain == null && keys == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _chain = chain;
        _keys = keys;
        _bypassChecksumValidation = bypassChecksumValidation ?? false;

        if (_chain?.slip44 == kZilliqaSlip44) {
          _zilLegacy = true;
        }

        _updatedArgs = true;
      });
    }

    if (!_walletNameInitialized) {
      _walletNameController.text = _generateWalletName();
      _walletNameInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();

    _appState = Provider.of<AppState>(context, listen: false);
    _walletNameController.text = '';

    _checkAuthMethods();
  }

  @override
  void dispose() {
    _bip39List?.zeroize();
    if (_keys != null) {
      _keys = _keys!.zeroize();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _walletNameController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  String _generateWalletName() {
    String type;
    if (_bip39List != null) {
      type = AppLocalizations.of(context)!.passwordSetupPageSeedType;
    } else if (_keys != null) {
      type = AppLocalizations.of(context)!.passwordSetupPageKeyType;
    } else {
      type = "";
    }

    String networkName = _chain?.name ??
        AppLocalizations.of(context)!.passwordSetupPageUniversalNetwork;
    int walletNumber = _appState.wallets.length + 1;
    return "$networkName #$walletNumber ($type)";
  }

  bool _validatePasswords() {
    if (_walletNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.passwordSetupPageEmptyWalletNameError;
        _disabled = false;
      });
      return false;
    }

    if (_walletNameController.text.length > 32) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.passwordSetupPageLongWalletNameError;
        _disabled = false;
      });
      return false;
    }

    if (_passwordController.text.length < 6) {
      _passwordInputKey.currentState?.shake();
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.passwordSetupPageShortPasswordError;
        _disabled = false;
      });
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordInputKey.currentState?.shake();
      setState(() {
        _disabled = false;
        _errorMessage = AppLocalizations.of(context)!
            .passwordSetupPageMismatchPasswordError;
      });
      return false;
    }
    return true;
  }

  void _createWallet() async {
    setState(() {
      _errorMessage = null;
      _disabled = true;
    });

    if (!_validatePasswords()) {
      _btnController.reset();
      return;
    }

    try {
      final l10n = AppLocalizations.of(context)!;
      final BigInt? chainHash;
      List<NetworkConfigInfo> chains = await getProviders();
      final matches = chains
          .where((chain) => chain.chainHash == _chain!.chainHash)
          .toList();

      if (matches.isEmpty) {
        chainHash = await addProvider(providerConfig: _chain!);
      } else {
        chainHash = matches.first.chainHash;
      }

      _btnController.start();

      String biometricType = "none";
      if (_useDeviceAuth && _authMethods.isNotEmpty) {
        biometricType = _authMethods[0];
      }

      WalletSettingsInfo settings = WalletSettingsInfo(
        cipherOrders: CipherDefaults.getCipherOrders(_selectedCipherIndex),
        argonParams: _argonParams,
        currencyConvert: detectDeviceCurrency(),
        ipfsNode: "dweb.link",
        ensEnabled: true,
        tokensListFetcher: true,
        nodeRankingEnabled: true,
        maxConnections: 5,
        requestTimeoutSecs: 30,
        ratesApiOptions: 1,
      );

      List<FTokenInfo> ftokens = [];

      // Compute bipPurpose from selector for Bitcoin, default for others
      final int bipPurpose;
      if (_chain?.slip44 == kBitcoinlip44) {
        final options = BipPurposeSelector.getBipPurposeOptions(l10n);
        bipPurpose = options[_selectedPurposeIndex].purpose;
      } else {
        bipPurpose = kBip44Purpose;
      }

      if (_bip39List != null) {
        Bip39AddWalletParams params = Bip39AddWalletParams(
          password: _passwordController.text,
          mnemonicStr: _bip39List!.join(' '),
          accounts: [(BigInt.zero, l10n.addAccountPageDefaultName(0))],
          passphrase: "",
          walletName: _walletNameController.text,
          biometricType: biometricType,
          chainHash: chainHash,
          mnemonicCheck: !_bypassChecksumValidation,
          bipPurpose: bipPurpose,
        );

        await addBip39Wallet(
          params: params,
          walletSettings: settings,
          additionalFtokens: ftokens,
        );
      } else if (_keys != null) {
        AddSKWalletParams params = AddSKWalletParams(
          sk: _keys!.sk,
          password: _passwordController.text,
          walletName: _walletNameController.text,
          biometricType: biometricType,
          chainHash: chainHash,
          bipPurpose: bipPurpose,
        );

        await addSkWallet(
          params: params,
          walletSettings: settings,
          ftokens: ftokens,
        );
      } else {
        throw "";
      }

      await _appState.syncData();
      _appState.setSelectedWallet(_appState.wallets.length - 1);
      await _appState.syncData();

      if (_zilLegacy && _chain?.slip44 == kZilliqaSlip44) {
        BigInt walletIndex = BigInt.from(_appState.selectedWallet);
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: _appState.wallet!.selectedAccount,
        );
        await _appState.syncData();
      }

      await _appState.startTrackHistoryWorker();

      _appState.setSelectedWallet(_appState.wallets.length - 1);
      _btnController.success();

      if (!mounted) return;
      _bip39List?.zeroize();
      if (_keys != null) {
        _keys = _keys!.zeroize();
      }
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      setState(() {
        _disabled = false;
        _errorMessage = e.toString();
      });
      _btnController.error();
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          _btnController.reset();
        }
      });
    }
  }

  void _showEncryptionModal() {
    showEncryptionSettingsModal(
      context: context,
      selectedCipherIndex: _selectedCipherIndex,
      argonParams: _argonParams,
      onSettingsChanged: (cipherIndex, argonParams) {
        setState(() {
          _selectedCipherIndex = cipherIndex;
          _argonParams = argonParams;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    const inputHeight = 50.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    title: AppLocalizations.of(context)!.passwordSetupPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!
                                .passwordSetupPageSubtitle,
                            style: theme.titleLarge.copyWith(
                              color: theme.textPrimary,
                            ),
                          ),
                          SizedBox(height: adaptivePadding),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _disabled ? null : _showEncryptionModal,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .cipherSettingsPageAdvancedButton,
                                  style: theme.bodyLarge.copyWith(
                                    color: _disabled
                                        ? theme.textSecondary
                                        : theme.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SmartInput(
                            controller: _walletNameController,
                            hint: AppLocalizations.of(context)!
                                .passwordSetupPageWalletNameHint,
                            fontSize: 18,
                            height: inputHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            focusedBorderColor: theme.primaryPurple,
                            disabled: _disabled,
                            onChanged: (value) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                          SizedBox(height: adaptivePadding),
                          SmartInput(
                            key: _passwordInputKey,
                            controller: _passwordController,
                            hint: AppLocalizations.of(context)!
                                .passwordSetupPagePasswordHint,
                            fontSize: 18,
                            height: inputHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            focusedBorderColor: theme.primaryPurple,
                            disabled: _disabled,
                            obscureText: _obscurePassword,
                            rightIconPath: _obscurePassword
                                ? "assets/icons/close_eye.svg"
                                : "assets/icons/open_eye.svg",
                            onChanged: (value) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                            onRightIconTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          SizedBox(height: adaptivePadding),
                          SmartInput(
                            key: _confirmPasswordInputKey,
                            controller: _confirmPasswordController,
                            hint: AppLocalizations.of(context)!
                                .passwordSetupPageConfirmPasswordHint,
                            height: inputHeight,
                            fontSize: 18,
                            disabled: _disabled,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            obscureText: _obscureConfirmPassword,
                            rightIconPath: _obscureConfirmPassword
                                ? "assets/icons/close_eye.svg"
                                : "assets/icons/open_eye.svg",
                            onRightIconTap: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            onChanged: (value) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          if (_errorMessage != null)
                            GlassMessage(
                              message: _errorMessage!,
                              type: GlassMessageType.error,
                            ),
                          if (_chain?.slip44 == kZilliqaSlip44)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/scilla.svg",
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          theme.textPrimary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .passwordSetupPageLegacyLabel,
                                        style: theme.bodyLarge.copyWith(
                                          color: theme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _zilLegacy,
                                    onChanged: _disabled
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _zilLegacy = value;
                                            });
                                          },
                                    activeThumbColor: theme.primaryPurple,
                                    activeTrackColor: theme.primaryPurple
                                        .withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
                          if (_authMethods.isNotEmpty)
                            BiometricSwitch(
                              biometricType: _authMethods.first,
                              value: _useDeviceAuth,
                              disabled: _disabled,
                              onChanged: (value) async {
                                setState(() => _useDeviceAuth = value);
                              },
                            ),
                          if (_chain?.slip44 == kBitcoinlip44)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: BipPurposeSelector(
                                selectedIndex: _selectedPurposeIndex,
                                onSelect: (index) => setState(
                                    () => _selectedPurposeIndex = index),
                                disabled: _disabled,
                              ),
                            ),
                          SizedBox(height: 80),
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
                      onPressed: _createWallet,
                      child: Text(
                        AppLocalizations.of(context)!
                            .passwordSetupPageCreateButton,
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

  Future<void> _checkAuthMethods() async {
    try {
      final methods = await getBiometricType();
      if (!mounted) return;
      setState(() {
        _authMethods = methods;
        if (_authMethods.isEmpty || _authMethods.first == "none") {
          _useDeviceAuth = false;
        }
      });
    } catch (e) {
      debugPrint("Error checking auth methods: $e");
      if (!mounted) return;
      setState(() {
        _authMethods = [];
        _useDeviceAuth = false;
      });
    }
  }
}
