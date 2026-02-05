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

  late final AppState _appState;

  bool _obscurePassword = true;
  bool _obscureButton = true;
  int _selectedWallet = -1;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
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
    Navigator.pushNamed(context, '/net_setup');
  }

  Future<void> _completeAuthentication(int walletIndex) async {
    _appState.setSelectedWallet(walletIndex);
    await _appState.syncData();
  }

  Future<bool> _authenticateWithSession(
    int walletIndex,
  ) async {
    try {
      bool unlocked = await tryUnlockWithSession(
        walletIndex: BigInt.from(walletIndex),
      );

      if (unlocked) {
        await _completeAuthentication(walletIndex);
        return true;
      }
      setState(() => _errorMessage = 'Session authentication failed');
    } catch (e) {
      debugPrint("session $e");
      setState(() => _errorMessage = e.toString());
    }
    return false;
  }

  Future<bool> _authenticateWithPassword(
    String password,
    int walletIndex,
  ) async {
    Future<bool> attemptUnlock(List<String>? identifiers) async {
      final unlocked = await tryUnlockWithPassword(
        password: password,
        walletIndex: BigInt.from(walletIndex),
        identifiers: identifiers,
      );

      if (unlocked) {
        await _completeAuthentication(walletIndex);
      }

      return unlocked;
    }

    try {
      if (await attemptUnlock(null)) {
        return true;
      }
    } catch (e) {
      debugPrint("1 attemp ${e.toString()}");
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      try {
        if (await attemptUnlock(identifiers)) {
          return true;
        }
      } catch (e) {
        debugPrint("2 attemp ${e.toString()}");
      }
    }

    setState(() => _errorMessage = 'Invalid password');
    return false;
  }

  Future<void> _handleAuthentication() async {
    final wallet = _selectedWallet >= 0
        ? _appState.wallets.elementAtOrNull(_selectedWallet)
        : null;

    if (wallet == null) return;

    _btnController.start();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      bool isAuthenticated = false;

      if (wallet.walletType.contains(WalletType.ledger.name)) {
        await _completeAuthentication(_selectedWallet);
        isAuthenticated = true;
      } else if (wallet.authType != "none" &&
          _passwordController.text.isEmpty) {
        isAuthenticated = await _authenticateWithSession(
          _selectedWallet,
        );
      } else if (_passwordController.text.isNotEmpty) {
        isAuthenticated = await _authenticateWithPassword(
          _passwordController.text,
          _selectedWallet,
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
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        _handleAuthenticationError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _btnController.reset();
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
    final wallet = _appState.wallets.elementAtOrNull(index);

    if (wallet == null) return const SizedBox.shrink();
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
          setState(() {
            _selectedWallet = index;
            _errorMessage = null;
          });
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
      if (wallet.authType == "faceId") 'assets/icons/face_id.svg',
      if (wallet.authType == "opticId") 'assets/icons/face_id.svg',
      if (wallet.authType == "fingerprint") 'assets/icons/fingerprint.svg',
      if (wallet.authType == "touchId") 'assets/icons/fingerprint.svg',
      if (wallet.authType == "biometric") 'assets/icons/biometric.svg',
      if (wallet.authType == "pinCode") 'assets/icons/pin.svg',
      if (wallet.authType == "password") 'assets/icons/pin.svg',
    ];
  }

  Widget? _buildErrorMessage(AppState theme) {
    if (_errorMessage == null) return null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.currentTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.currentTheme.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        _errorMessage!,
        style: theme.currentTheme.bodyText2.copyWith(
          color: theme.currentTheme.danger,
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppState theme) {
    final wallet = _selectedWallet >= 0
        ? _appState.wallets.elementAtOrNull(_selectedWallet)
        : null;
    final isLedgerWallet =
        wallet?.walletType.contains(WalletType.ledger.name) ?? false;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(AdaptiveSize.getAdaptivePadding(context, 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) _buildErrorMessage(theme)!,
          SmartInput(
            key: _passwordInputKey,
            controller: _passwordController,
            hint: l10n.loginPagePasswordHint,
            fontSize: 18,
            height: 50,
            disabled: _selectedWallet == -1 || isLedgerWallet || _loading,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            focusedBorderColor: theme.currentTheme.primaryPurple,
            obscureText: _obscurePassword,
            onSubmitted: (_) => _handleAuthentication(),
            onFocusChanged: (isFocused) => setState(() {
              _obscureButton = !isFocused;
              if (isFocused) _errorMessage = null;
            }),
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
    final appState = Provider.of<AppState>(context, listen: false);
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
