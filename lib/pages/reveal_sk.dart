import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/async_qrcode.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/hex_key.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/reveal_password_form.dart';
import 'package:bearby/components/reveal_scam_alert.dart';
import 'package:bearby/components/reveal_security_timer.dart';
import 'package:bearby/components/wallet_card.dart';
import 'package:bearby/config/settings.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/auth.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/src/rust/models/keypair.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

class RevealSecretKey extends StatefulWidget {
  const RevealSecretKey({super.key});

  @override
  State<RevealSecretKey> createState() => _RevealSecretKeyState();
}

class _RevealSecretKeyState extends State<RevealSecretKey> with StatusBarMixin {
  bool _isCopied = false;
  bool _isAuthenticated = false;
  bool _isTimerActive = false;
  bool _canShowKey = false;
  bool _isLoadingKey = false;
  bool _obscurePassword = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _password;
  KeyPairInfo? _keys;

  /// List index into [AppState.accounts] — same convention as [WalletInfo.selectedAccount].
  int? _selectedListIndex;

  Timer? _countdownTimer;
  int _remainingTime = SecuritySettings.revealDelaySeconds;

  /// Cached keys keyed by list index — avoids re-fetching on switch.
  final Map<int, KeyPairInfo> _keyCache = <int, KeyPairInfo>{};

  final _passwordController = TextEditingController();
  final _btnController = RoundedLoadingButtonController();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _passwordController.dispose();
    _password = null;
    _keyCache.clear();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isTimerActive = true;
      _remainingTime = SecuritySettings.revealDelaySeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
        return;
      }
      timer.cancel();
      setState(() {
        _canShowKey = true;
        _isTimerActive = false;
      });
      _loadKeyForSelected();
    });
  }

  Future<void> _onPasswordSubmit(BigInt walletIndex) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final password = _passwordController.text;
    _btnController.start();
    try {
      await tryUnlockWithPassword(
        password: password,
        walletIndex: walletIndex,
      );

      if (!mounted) return;

      final state = context.read<AppState>();
      final defaultIndex = (state.wallet?.selectedAccount ?? BigInt.zero).toInt();

      setState(() {
        _password = password;
        _selectedListIndex = defaultIndex;
        _isAuthenticated = true;
        _hasError = false;
        _errorMessage = null;
      });
      _passwordController.clear();
      _btnController.success();
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _hasError = true;
        _errorMessage = '${l10n.revealSecretKeyInvalidPassword} $e';
      });
      _btnController.error();
      await Future<void>.delayed(SecuritySettings.errorResetDuration);
      if (mounted) _btnController.reset();
    }
  }

  Future<void> _selectAccount(int listIndex) async {
    if (_selectedListIndex == listIndex && _keys != null) return;

    setState(() {
      _selectedListIndex = listIndex;
      _isCopied = false;
      _keys = _keyCache[listIndex];
      _hasError = false;
      _errorMessage = null;
    });

    if (!_canShowKey) return;
    await _loadKeyForSelected();
  }

  Future<void> _loadKeyForSelected() async {
    final listIndex = _selectedListIndex;
    final password = _password;
    if (listIndex == null || password == null || !_canShowKey) return;

    final cached = _keyCache[listIndex];
    if (cached != null) {
      if (mounted) setState(() => _keys = cached);
      return;
    }

    final state = context.read<AppState>();
    final walletIndex = state.selectedWalletIndexOrNull;
    if (walletIndex == null) return;

    setState(() {
      _isLoadingKey = true;
      _hasError = false;
      _errorMessage = null;
    });
    try {
      final keypair = await revealKeypair(
        walletIndex: walletIndex,
        accountIndex: BigInt.from(listIndex),
        password: password,
      );
      if (!mounted) return;
      _keyCache[listIndex] = keypair;
      setState(() {
        _keys = keypair;
        _isLoadingKey = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingKey = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleCopy(String key) async {
    if (key.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: key));
    if (!mounted) return;
    setState(() => _isCopied = true);
    await Future<void>.delayed(SecuritySettings.copyFeedbackDuration);
    if (mounted) setState(() => _isCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.currentTheme;
    final l10n = AppLocalizations.of(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final accounts = state.accounts;
    final sk = _keys?.sk;
    final canCopy = _canShowKey && sk != null && sk.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
              child: CustomAppBar(
                title: l10n?.revealSecretKeyTitle ?? '',
                onBackPressed: () => Navigator.pop(context),
                actionIcon: canCopy
                    ? AppIconView(
                        icon: _isCopied ? AppIcon.check : AppIcon.copy,
                        size: 24,
                        color: theme.textPrimary,
                      )
                    : null,
                onActionPressed: canCopy ? () => _handleCopy(sk) : null,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                children: [
                  RevealScamAlert(
                    theme: theme,
                    message: l10n?.revealSecretKeyScamAlertMessage ?? '',
                  ),
                  if (!_isAuthenticated)
                    RevealPasswordForm(
                      controller: _passwordController,
                      btnController: _btnController,
                      theme: theme,
                      passwordHint: l10n?.revealSecretKeyPasswordHint ?? '',
                      submitLabel: l10n?.revealSecretKeySubmitButton ?? '',
                      obscurePassword: _obscurePassword,
                      hasError: _hasError,
                      errorMessage: _errorMessage,
                      onToggleObscure: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      onSubmit: () {
                        final walletIndex = state.selectedWalletIndexOrNull;
                        if (walletIndex == null) return;
                        _onPasswordSubmit(walletIndex);
                      },
                    ),
                  if (_isAuthenticated) ...[
                    _AccountList(
                      accounts: accounts,
                      selectedIndex: _selectedListIndex,
                      onSelect: _selectAccount,
                    ),
                    if (_isTimerActive && !_canShowKey)
                      RevealSecurityTimer(
                        theme: theme,
                        remainingSeconds: _remainingTime,
                      ),
                    if (_canShowKey)
                      _KeySection(
                        theme: theme,
                        state: state,
                        keys: _keys,
                        isLoading: _isLoadingKey,
                        hasError: _hasError,
                        errorMessage: _errorMessage,
                        adaptivePadding: adaptivePadding,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reuses [WalletCard] — same card users already know from the wallet switcher.
class _AccountList extends StatelessWidget {
  final List<AccountInfo> accounts;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _AccountList({
    required this.accounts,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.32;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          return WalletCard(
            account: accounts[index],
            isSelected: selectedIndex == index,
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }
}

/// QR + hex key for the selected account.
class _KeySection extends StatelessWidget {
  final AppTheme theme;
  final AppState state;
  final KeyPairInfo? keys;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final double adaptivePadding;

  const _KeySection({
    required this.theme,
    required this.state,
    required this.keys,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.adaptivePadding,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: adaptivePadding * 2),
        child: Center(
          child: CircularProgressIndicator(color: theme.primaryPurple),
        ),
      );
    }

    final sk = keys?.sk;
    if (sk == null || sk.isEmpty) {
      if (hasError && errorMessage != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            errorMessage ?? '',
            style: theme.bodyText2.copyWith(color: theme.danger),
            textAlign: TextAlign.center,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final chain = state.chain;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chain != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: adaptivePadding),
            child: Center(
              child: AsyncQRcode(
                data: generateQRSecretData(
                  chain: chain.shortName,
                  privateKey: sk,
                ),
                size: 140,
                color: theme.danger,
                eyeShape: EyeShape.circle,
                dataModuleShape: DataModuleShape.circle,
                loadingWidget: CircularProgressIndicator(color: theme.danger),
              ),
            ),
          ),
        HexKeyDisplay(hexKey: sk),
        SizedBox(height: adaptivePadding),
      ],
    );
  }
}
