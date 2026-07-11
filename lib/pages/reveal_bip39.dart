import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/async_qrcode.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/reveal_password_form.dart';
import 'package:bearby/components/reveal_scam_alert.dart';
import 'package:bearby/components/reveal_security_timer.dart';
import 'package:bearby/config/settings.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/auth.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

class RevealSecretPhrase extends StatefulWidget {
  const RevealSecretPhrase({super.key});

  @override
  State<RevealSecretPhrase> createState() => _RevealSecretPhraseState();
}

class _RevealSecretPhraseState extends State<RevealSecretPhrase>
    with StatusBarMixin {
  bool _isCopied = false;
  bool _isAuthenticated = false;
  bool _isTimerActive = false;
  bool _canShowPhrase = false;
  bool _obscurePassword = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _seedPhrase;
  Timer? _countdownTimer;
  int _remainingTime = SecuritySettings.revealDelaySeconds;

  final _passwordController = TextEditingController();
  final _btnController = RoundedLoadingButtonController();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _passwordController.dispose();
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
        _canShowPhrase = true;
        _isTimerActive = false;
      });
    });
  }

  Future<void> _onPasswordSubmit(BigInt walletIndex) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    _btnController.start();
    try {
      await tryUnlockWithPassword(
        password: _passwordController.text,
        walletIndex: walletIndex,
      );

      final phrase = await revealBip39Phrase(
        walletIndex: walletIndex,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _seedPhrase = phrase;
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
        _errorMessage =
            '${l10n.revealSecretPhraseInvalidPassword} $e';
      });
      _btnController.error();
      await Future<void>.delayed(SecuritySettings.errorResetDuration);
      if (mounted) _btnController.reset();
    }
  }

  Future<void> _handleCopy(String phrase) async {
    if (phrase.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: phrase));
    if (!mounted) return;
    setState(() => _isCopied = true);
    await Future<void>.delayed(SecuritySettings.copyFeedbackDuration);
    if (mounted) setState(() => _isCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = state.currentTheme;
    final l10n = AppLocalizations.of(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final phrase = _seedPhrase;
    final canCopy = _canShowPhrase && phrase != null && phrase.isNotEmpty;

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
                title: l10n?.revealSecretPhraseTitle ?? '',
                onBackPressed: () => Navigator.pop(context),
                actionIcon: canCopy
                    ? AppIconView(
                        icon: _isCopied ? AppIcon.check : AppIcon.copy,
                        size: 24,
                        color: theme.textPrimary,
                      )
                    : null,
                onActionPressed: canCopy ? () => _handleCopy(phrase) : null,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  children: [
                    RevealScamAlert(
                      theme: theme,
                      message:
                          l10n?.revealSecretPhraseScamAlertDescription ?? '',
                    ),
                    if (!_isAuthenticated)
                      RevealPasswordForm(
                        controller: _passwordController,
                        btnController: _btnController,
                        theme: theme,
                        passwordHint:
                            l10n?.revealSecretPhrasePasswordHint ?? '',
                        submitLabel:
                            l10n?.revealSecretPhraseSubmitButton ?? '',
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
                    if (_isAuthenticated &&
                        _isTimerActive &&
                        !_canShowPhrase)
                      RevealSecurityTimer(
                        theme: theme,
                        remainingSeconds: _remainingTime,
                      ),
                    if (_isAuthenticated &&
                        _canShowPhrase &&
                        phrase != null) ...[
                      _buildQrCode(theme, state, phrase, adaptivePadding),
                      _PhraseGrid(phrase: phrase, theme: theme),
                      SizedBox(height: adaptivePadding),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: adaptivePadding),
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: l10n?.revealSecretPhraseDoneButton ?? '',
                            onPressed: () => Navigator.pop(context),
                            borderRadius: 30.0,
                            height: 56.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCode(
    AppTheme theme,
    AppState state,
    String phrase,
    double adaptivePadding,
  ) {
    final chain = state.chain;
    if (chain == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: adaptivePadding),
      child: Center(
        child: AsyncQRcode(
          data: generateQRSecretData(
            chain: chain.shortName,
            seedPhrase: phrase,
          ),
          size: 160,
          color: theme.danger,
          eyeShape: EyeShape.circle,
          dataModuleShape: DataModuleShape.circle,
          loadingWidget: CircularProgressIndicator(color: theme.danger),
        ),
      ),
    );
  }
}

class _PhraseGrid extends StatelessWidget {
  final String phrase;
  final AppTheme theme;

  const _PhraseGrid({
    required this.phrase,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final words = phrase.split(' ');
    const itemsPerRow = 3;
    final rowCount = (words.length / itemsPerRow).ceil();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.secondaryPurple),
      ),
      child: Column(
        children: List.generate(rowCount, (rowIndex) {
          final startIndex = rowIndex * itemsPerRow;
          final endIndex = (startIndex + itemsPerRow).clamp(0, words.length);
          final count = endIndex - startIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(count, (index) {
                final wordIndex = startIndex + index;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index != itemsPerRow - 1 ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${wordIndex + 1}. ${words[wordIndex]}',
                      style: theme.overline.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
