import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/state/app_state.dart';

class BiometricSwitch extends StatelessWidget {
  final AuthMethod biometricType;
  final bool value;
  final bool disabled;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;

  const BiometricSwitch({
    super.key,
    required this.biometricType,
    required this.value,
    this.disabled = false,
    this.isLoading = false,
    this.onChanged,
  });

  String _authMethodText(BuildContext context) {
    switch (biometricType) {
      case AuthMethod.faceId:
        return AppLocalizations.of(context)!.biometricSwitchFaceId;
      case AuthMethod.fingerprint:
        return AppLocalizations.of(context)!.biometricSwitchFingerprint;
      case AuthMethod.biometric:
        return AppLocalizations.of(context)!.biometricSwitchBiometric;
      case AuthMethod.pinCode:
        return AppLocalizations.of(context)!.biometricSwitchPinCode;
      case AuthMethod.none:
        return '';
    }
  }

  String get _iconPath {
    switch (biometricType) {
      case AuthMethod.faceId:
        return 'assets/icons/face_id.svg';
      case AuthMethod.fingerprint:
        return 'assets/icons/fingerprint.svg';
      case AuthMethod.biometric:
        return 'assets/icons/biometric.svg';
      case AuthMethod.pinCode:
        return 'assets/icons/pin.svg';
      case AuthMethod.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (biometricType == AuthMethod.none) {
      return const SizedBox.shrink();
    }

    final theme = Provider.of<AppState>(context).currentTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                _iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  theme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _authMethodText(context),
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          isLoading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: CupertinoActivityIndicator(
                    color: theme.primaryPurple,
                  ),
                )
              : Switch(
                  value: value,
                  onChanged: disabled ? null : onChanged,
                  activeColor: theme.primaryPurple,
                  activeTrackColor: theme.primaryPurple.withValues(alpha: 0.4),
                ),
        ],
      ),
    );
  }
}
