import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/theme/theme_provider.dart';

class BiometricSwitch extends StatelessWidget {
  final AuthMethod biometricType;
  final bool value;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  const BiometricSwitch({
    super.key,
    required this.biometricType,
    required this.value,
    this.disabled = false,
    this.onChanged,
  });

  String get _authMethodText {
    switch (biometricType) {
      case AuthMethod.faceId:
        return 'Enable Face ID';
      case AuthMethod.fingerprint:
        return 'Enable Fingerprint';
      case AuthMethod.biometric:
        return 'Enable Biometric Login';
      case AuthMethod.pinCode:
        return 'Enable Device PIN';
      case AuthMethod.none:
      default:
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
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (biometricType == AuthMethod.none) {
      return const SizedBox.shrink();
    }

    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
                _authMethodText,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeColor: theme.primaryPurple,
            activeTrackColor: theme.primaryPurple.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}
