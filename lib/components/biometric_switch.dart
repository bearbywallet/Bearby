import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/state/app_state.dart';

class BiometricSwitch extends StatelessWidget {
  final String biometricType;
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
      case "touchId":
        return AppLocalizations.of(context)!.biometricSwitchTouchId;
      case "faceId":
        return AppLocalizations.of(context)!.biometricSwitchFaceId;
      case "opticId":
        return AppLocalizations.of(context)!.biometricSwitchOpticId;
      case "fingerprint":
        return AppLocalizations.of(context)!.biometricSwitchFingerprint;
      case "biometric":
        return AppLocalizations.of(context)!.biometricSwitchBiometric;
      case "password":
        return AppLocalizations.of(context)!.biometricSwitchPinCode;
      case "none":
      default:
        return '';
    }
  }

  String get _iconPath {
    switch (biometricType) {
      case "touchId":
        return 'assets/icons/fingerprint.svg';
      case "faceId":
        return 'assets/icons/face_id.svg';
      case "opticId":
        return 'assets/icons/face_id.svg';
      case "fingerprint":
        return 'assets/icons/fingerprint.svg';
      case "biometric":
        return 'assets/icons/biometric.svg';
      case "password":
        return 'assets/icons/pin.svg';
      case "none":
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (biometricType == "none") {
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
                style: theme.bodyText1.copyWith(
                  color: theme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
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
                  activeThumbColor: theme.primaryPurple,
                  activeTrackColor: theme.primaryPurple.withValues(alpha: 0.4),
                ),
        ],
      ),
    );
  }
}
