import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/src/rust/models/wallet.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/status_bar.dart';

import '../components/load_button.dart';
import '../components/smart_input.dart';
import '../components/wallet_option.dart';
import '../mixins/adaptive_size.dart';
import '../mixins/wallet_type.dart';
import '../services/auth_guard.dart';
import '../services/biometric_service.dart';
import '../services/device.dart';
import '../state/app_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with StatusBarMixin {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();
  final AuthService _authService = AuthService();

  late final AuthGuard _authGuard;
  late final AppState _appState;

  bool _obscurePassword = true;
  bool _obscureButton = true;
  int _selectedWallet = -1;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _authGuard = Provider.of<AuthGuard>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_appState.wallets.isEmpty) {
      setState(() => _selectedWallet = -1);
      Navigator.of(context).pushNamed('/initial');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    _appState.setSelectedWallet(_selectedWallet);
    Navigator.of(context).pushNamed('/');
  }

  void _navigateToNewWallet() {
    Navigator.pushNamed(context, '/new_wallet_options');
  }

  Future<bool> _authenticateWithSession(
    String session,
    int walletIndex,
    List<String> identifiers,
  ) async {
    try {
      bool unlocked = await tryUnlockWithSession(
        sessionCipher: session,
        walletIndex: BigInt.from(walletIndex),
        identifiers: identifiers,
      );

      if (unlocked) {
        _appState.setSelectedWallet(walletIndex);
        await _appState.syncData();
        _authGuard.setEnabled(true);
        return true;
      }
    } catch (e) {
      debugPrint('Session authentication error: $e');
    }
    return false;
  }

  Future<bool> _authenticateWithPassword(
    String password,
    int walletIndex,
    List<String> identifiers,
  ) async {
    try {
      bool unlocked = await tryUnlockWithPassword(
        password: password,
        walletIndex: BigInt.from(walletIndex),
        identifiers: identifiers,
      );

      if (unlocked) {
        _appState.setSelectedWallet(walletIndex);
        await _appState.syncData();
        _authGuard.setEnabled(true);
        return true;
      }
    } catch (e) {
      debugPrint('Password authentication error: $e');
    }
    return false;
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _authService.authenticate(
        allowPinCode: true,
        reason: AppLocalizations.of(context)!.loginPageBiometricReason,
      );
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  Future<void> _handleAuthentication() async {
    if (_selectedWallet == -1 || _appState.wallets.isEmpty) return;

    final wallet = _appState.wallets[_selectedWallet];
    final device = DeviceInfoService();
    final identifiers = await device.getDeviceIdentifiers();

    _btnController.start();

    try {
      bool isAuthenticated = false;

      if (wallet.walletType.contains(WalletType.ledger.name)) {
        final session =
            await _authGuard.getSession(sessionKey: wallet.walletAddress);
        isAuthenticated = await _authenticateWithSession(
          session ?? "",
          _selectedWallet,
          identifiers,
        );
      } else if (wallet.authType != AuthMethod.none.name &&
          _passwordController.text.isEmpty) {
        final biometricAuth = await _authenticateWithBiometrics();
        if (biometricAuth) {
          final session =
              await _authGuard.getSession(sessionKey: wallet.walletAddress);
          isAuthenticated = await _authenticateWithSession(
            session ?? "",
            _selectedWallet,
            identifiers,
          );
        }
      } else if (_passwordController.text.isNotEmpty) {
        isAuthenticated = await _authenticateWithPassword(
          _passwordController.text,
          _selectedWallet,
          identifiers,
        );
      } else {
        if (mounted) {
          _btnController.reset();
        }
        return;
      }

      if (isAuthenticated) {
        if (mounted) {
          _btnController.reset();
        }
        _navigateToHome();
      } else {
        if (mounted) {
          _handleAuthenticationError();
        }
      }

      await _appState.startTrackHistoryWorker();
    } catch (e) {
      debugPrint("unlock $e");
      if (mounted) {
        _handleAuthenticationError();
      }
    }
  }

  void _handleAuthenticationError() {
    if (mounted) {
      _btnController.error();
      if (_passwordController.text.isNotEmpty) {
        _passwordInputKey.currentState?.shake();
      }
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          _btnController.reset();
        }
      });
    }
  }

  Widget _buildBackground(Size screenSize) {
    return Positioned(
      child: SizedBox(
        height: screenSize.height * 0.6,
        child: Transform.scale(
          scale: 1.4,
          child: SvgPicture.asset(
            'assets/imgs/zilpay.svg',
            fit: BoxFit.cover,
            width: screenSize.width,
            height: screenSize.height * 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppState theme) {
    return Padding(
      padding: EdgeInsets.all(AdaptiveSize.getAdaptivePadding(context, 16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          IconButton(
            onPressed: _navigateToNewWallet,
            icon: SvgPicture.asset(
              'assets/icons/plus.svg',
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(
                theme.currentTheme.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletList(AppState theme) {
    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: AdaptiveSize.getAdaptivePadding(context, 16),
        ),
        itemCount: _appState.wallets.length,
        itemBuilder: (context, index) => _buildWalletItem(index, theme),
      ),
    );
  }

  Widget _buildWalletItem(int index, AppState theme) {
    if (index >= _appState.wallets.length) return const SizedBox.shrink();

    final wallet = _appState.wallets[index];
    final l10n = AppLocalizations.of(context)!;

    if (!_obscureButton && _selectedWallet != index) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 4 : 0),
      child: WalletOption(
        title: wallet.walletName.isEmpty
            ? l10n.loginPageWalletTitle(index + 1)
            : wallet.walletName,
        walletIndex: index,
        address: wallet.walletAddress,
        isSelected: _selectedWallet == index,
        padding: const EdgeInsets.all(16),
        onTap: () {
          setState(() => _selectedWallet = index);
          _handleAuthentication();
        },
        icons: _getWalletIcons(wallet),
      ),
    );
  }

  List<String> _getWalletIcons(WalletInfo wallet) {
    return [
      if (wallet.walletType.contains(WalletType.ledger.name))
        'assets/icons/ledger.svg',
      if (wallet.walletType.contains(WalletType.SecretPhrase.name))
        'assets/icons/document.svg',
      if (wallet.walletType.contains(WalletType.SecretKey.name))
        'assets/icons/bincode.svg',
      if (wallet.authType == AuthMethod.faceId.name) 'assets/icons/face_id.svg',
      if (wallet.authType == AuthMethod.fingerprint.name)
        'assets/icons/fingerprint.svg',
      if (wallet.authType == AuthMethod.biometric.name)
        'assets/icons/biometric.svg',
      if (wallet.authType == AuthMethod.pinCode.name) 'assets/icons/pin.svg',
    ];
  }

  Widget _buildLoginForm(AppState theme) {
    final isLedgerWallet = _selectedWallet != -1 &&
        _selectedWallet < _appState.wallets.length &&
        _appState.wallets[_selectedWallet].walletType
            .contains(WalletType.ledger.name);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(AdaptiveSize.getAdaptivePadding(context, 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmartInput(
            key: _passwordInputKey,
            controller: _passwordController,
            hint: l10n.loginPagePasswordHint,
            fontSize: 18,
            height: 50,
            disabled: _selectedWallet == -1 || isLedgerWallet,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            focusedBorderColor: theme.currentTheme.primaryPurple,
            obscureText: _obscurePassword,
            onSubmitted: (_) => _handleAuthentication(),
            onFocusChanged: (isFocused) =>
                setState(() => _obscureButton = !isFocused),
            rightIconPath: _obscurePassword
                ? "assets/icons/close_eye.svg"
                : "assets/icons/open_eye.svg",
            onRightIconTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 8),
          if (_obscureButton) _buildUnlockButton(theme),
        ],
      ),
    );
  }

  Widget _buildUnlockButton(AppState appState) {
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: RoundedLoadingButton(
        color: theme.primaryPurple,
        valueColor: theme.buttonText,
        controller: _btnController,
        onPressed: _handleAuthentication,
        child: Text(
          l10n.loginPageUnlockButton,
          style: theme.titleSmall.copyWith(
            color: theme.buttonText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenSize = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    if (appState.wallets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: appState.currentTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: Stack(
        children: [
          _buildBackground(screenSize),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    _buildHeader(appState),
                    Text(
                      l10n.loginPageWelcomeBack,
                      style: appState.currentTheme.displayLarge.copyWith(
                        color: appState.currentTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWalletList(appState),
                    _buildLoginForm(appState),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
