import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bearby/config/settings.dart';

/// Shared reveal-screen machinery: copy-with-feedback and the security
/// countdown gate. `reveal_bip39` and `reveal_sk` used to carry verbatim
/// copies of both (DRY); the countdown takes an [onCompleted] hook because
/// the SK page loads its key when the timer ends.
mixin RevealSecretMixin<T extends StatefulWidget> on State<T> {
  bool _isCopied = false;
  bool _isTimerActive = false;
  bool _canShowSecret = false;
  Timer? _countdownTimer;
  int _remainingTime = SecuritySettings.revealDelaySeconds;

  bool get isCopied => _isCopied;
  bool get isTimerActive => _isTimerActive;
  bool get canShowSecret => _canShowSecret;
  int get remainingTime => _remainingTime;

  @protected
  void setCopied(bool value) => _isCopied = value;

  @protected
  void setCanShowSecret(bool value) => _canShowSecret = value;

  void disposeRevealSecret() {
    _countdownTimer?.cancel();
  }

  @protected
  void startCountdown({VoidCallback? onCompleted}) {
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
        _canShowSecret = true;
        _isTimerActive = false;
      });
      onCompleted?.call();
    });
  }

  @protected
  Future<void> handleCopy(String secret) async {
    if (secret.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: secret));
    if (!mounted) return;
    setState(() => _isCopied = true);
    await Future<void>.delayed(SecuritySettings.copyFeedbackDuration);
    if (mounted) setState(() => _isCopied = false);
  }
}
