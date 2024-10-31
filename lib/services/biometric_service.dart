import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

enum AuthMethod { faceId, fingerprint, biometric, pinCode, none }

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<List<AuthMethod>> getAvailableAuthMethods() async {
    try {
      List<AuthMethod> methods = [];

      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;

      if (isSupported && canCheckBiometrics) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        final biometricInfo = await _getBiometricInfo();

        if (biometricInfo.contains('face')) {
          methods.add(AuthMethod.faceId);
        } else if (biometricInfo.contains('fingerprint') ||
            biometricInfo.contains('thumb') ||
            biometricInfo.contains('finger')) {
          methods.add(AuthMethod.fingerprint);
        } else if (availableBiometrics.contains(BiometricType.strong) ||
            availableBiometrics.contains(BiometricType.weak)) {
          methods.add(AuthMethod.biometric);
        }
      }

      if (await _checkDevicePinCode()) {
        methods.add(AuthMethod.pinCode);
      }

      return methods.isEmpty ? [AuthMethod.none] : methods;
    } on PlatformException catch (_) {
      return [AuthMethod.none];
    }
  }

  Future<String> _getBiometricInfo() async {
    try {
      final String biometricHint = await _auth.getAvailableBiometrics().then(
        (types) async {
          if (types.isNotEmpty) {
            final authenticated = await _auth
                .authenticate(
                  localizedReason: '',
                  options: const AuthenticationOptions(
                    biometricOnly: true,
                    useErrorDialogs: false,
                  ),
                )
                .catchError((_) => false);
            return '';
          }
          return '';
        },
      );
      return biometricHint.toLowerCase();
    } catch (e) {
      return '';
    }
  }

  Future<bool> _checkDevicePinCode() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    bool allowPinCode = true,
    String reason = 'Please authenticate to continue',
  }) async {
    return await _auth.authenticate(
      localizedReason: reason,
      options: AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: !allowPinCode,
        useErrorDialogs: true,
      ),
    );
  }
}
