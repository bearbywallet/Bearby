import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/state/app_state.dart';

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
      case "pinCode":
        return AppLocalizations.of(context)!.biometricSwitchPinCode;
      case "none":
      default:
        return '';
    }
  }

  AppIcon? get _icon {
    switch (biometricType) {
      case "touchId":
      case "fingerprint":
        return AppIcon.fingerprint;
      case "faceId":
      case "opticId":
        return AppIcon.faceId;
      case "biometric":
        return AppIcon.biometric;
      case "password":
      case "pinCode":
        return AppIcon.pin;
      case "none":
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (biometricType == "none") {
      return const SizedBox.shrink();
    }

    final theme = Provider.of<AppState>(context).currentTheme;
    final icon = _icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                AppIconView(
                  icon: icon,
                  size: 24,
                  color: theme.textPrimary,
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
