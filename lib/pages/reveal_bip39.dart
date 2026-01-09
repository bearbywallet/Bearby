import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/async_qrcode.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/auth.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/qrcode.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class RevealSecretPhrase extends StatefulWidget {
  const RevealSecretPhrase({super.key});

  @override
  State<RevealSecretPhrase> createState() => _RevealSecretPhraseState();
}

class _RevealSecretPhraseState extends State<RevealSecretPhrase>
    with StatusBarMixin {
  bool isCopied = false;
  bool isAuthenticated = false;
  bool hasError = false;
  bool isTimerActive = false;
  bool canShowPhrase = false;
  String? errorMessage;
  bool _obscurePassword = true;
  String? seedPhrase;
  Timer? _countdownTimer;
  int _remainingTime = 3600;

  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      isTimerActive = true;
      _remainingTime = 3600;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          canShowPhrase = true;
          isTimerActive = false;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onPasswordSubmit(BigInt walletIndex) async {
    _btnController.start();
    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      await tryUnlockWithPassword(
        password: _passwordController.text,
        walletIndex: walletIndex,
        identifiers: identifiers,
      );

      String phrase = await revealBip39Phrase(
        walletIndex: walletIndex,
        identifiers: identifiers,
        password: _passwordController.text,
      );

      setState(() {
        seedPhrase = phrase;
        isAuthenticated = true;
        hasError = false;
        errorMessage = null;
      });

      _btnController.success();
      _startCountdown();
    } catch (e) {
      setState(() {
        isAuthenticated = false;
        hasError = true;
        errorMessage =
            "${AppLocalizations.of(context)!.revealSecretPhraseInvalidPassword} $e";
      });
      _btnController.error();
      await Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = state.currentTheme;

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
                title: AppLocalizations.of(context)!.revealSecretPhraseTitle,
                onBackPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  children: [
                    _buildScamAlert(theme),
                    if (!isAuthenticated) ...[
                      SmartInput(
                        key: _passwordInputKey,
                        controller: _passwordController,
                        hint: AppLocalizations.of(context)!
                            .revealSecretPhrasePasswordHint,
                        fontSize: 18,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        focusedBorderColor: theme.primaryPurple,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _onPasswordSubmit(
                          BigInt.from(state.selectedWallet),
                        ),
                        rightIconPath: _obscurePassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      if (hasError && errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorMessage!,
                            style: theme.bodyText2.copyWith(
                              color: theme.danger,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: RoundedLoadingButton(
                          color: theme.primaryPurple,
                          valueColor: theme.buttonText,
                          controller: _btnController,
                          onPressed: () => _onPasswordSubmit(
                            BigInt.from(state.selectedWallet),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .revealSecretPhraseSubmitButton,
                            style: theme.titleSmall.copyWith(
                              color: theme.buttonText,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isAuthenticated && isTimerActive && !canShowPhrase) ...[
                      _buildTimerDisplay(theme),
                    ],
                    if (isAuthenticated &&
                        canShowPhrase &&
                        seedPhrase != null) ...[
                      _buildQrCode(theme),
                      _buildPhraseDisplay(theme),
                      SizedBox(height: adaptivePadding),
                      TileButton(
                        icon: SvgPicture.asset(
                          isCopied
                              ? "assets/icons/check.svg"
                              : "assets/icons/copy.svg",
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            theme.primaryPurple,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () => _handleCopy(seedPhrase ?? ""),
                        backgroundColor: theme.cardBackground,
                        textColor: theme.primaryPurple,
                      ),
                      SizedBox(height: adaptivePadding),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: EdgeInsets.only(bottom: adaptivePadding),
                        child: CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: AppLocalizations.of(context)!
                              .revealSecretPhraseDoneButton,
                          onPressed: () => Navigator.pop(context),
                          borderRadius: 30.0,
                          height: 56.0,
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

  Widget _buildTimerDisplay(AppTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.secondaryPurple),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            "assets/icons/time.svg",
            width: 48,
            height: 48,
            colorFilter: ColorFilter.mode(
              theme.primaryPurple,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Security Timer",
            style: theme.subtitle1.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.revealSecretPhraseRevealAfter,
            style: theme.bodyText2.copyWith(
              color: theme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _formatTime(_remainingTime),
            style: theme.displayLarge.copyWith(
              color: theme.primaryPurple,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 1 - (_remainingTime / 3600),
            backgroundColor: theme.background,
            valueColor: AlwaysStoppedAnimation(theme.primaryPurple),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildScamAlert(AppTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.danger),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/icons/warning.svg",
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  theme.danger,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.revealSecretPhraseScamAlertTitle,
                style: theme.labelLarge.copyWith(
                  color: theme.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!
                .revealSecretPhraseScamAlertDescription,
            style: theme.bodyText2.copyWith(
              color: theme.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseDisplay(AppTheme theme) {
    final List<String> words = seedPhrase?.split(' ') ?? [];
    final int itemsPerRow = 3;
    final int rowCount = (words.length / itemsPerRow).ceil();

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

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(
                endIndex - startIndex,
                (index) => Expanded(
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
                      '${startIndex + index + 1}. ${words[startIndex + index]}',
                      style: theme.overline.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQrCode(AppTheme theme) {
    final state = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final chain = state.chain!;

    return Container(
      margin: EdgeInsets.symmetric(vertical: adaptivePadding),
      child: Center(
        child: AsyncQRcode(
          data: generateQRSecretData(
            chain: chain.shortName,
            seedPhrase: seedPhrase,
          ),
          size: 160,
          color: theme.danger,
          eyeShape: EyeShape.circle,
          dataModuleShape: DataModuleShape.circle,
          loadingWidget: CircularProgressIndicator(
            color: theme.danger,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCopy(String phrase) async {
    await Clipboard.setData(ClipboardData(text: phrase));
    setState(() {
      isCopied = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    setState(() {
      isCopied = false;
    });
  }
}
