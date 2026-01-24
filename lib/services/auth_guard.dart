import 'package:zilpay/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:zilpay/state/app_state.dart';

class AuthGuard extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  final AppState _state;

  bool _enabled = false;

  bool get ready => _state.wallets.isNotEmpty;
  bool get enabled => _enabled;

  AuthGuard({required AppState state})
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: true,
          ),
        ),
        _state = state;

  void setEnabled(bool value) {
    _enabled = value;
  }

  Future<void> setSession(String sessionKey, String sessionValue) async {
    final AuthService authService = AuthService();

    try {
      final authMethods = await authService.getAvailableAuthMethods();

      if (authMethods.contains(AuthMethod.none)) {
        throw 'Device does not support secure storage. Please enable device lock.';
      }

      await _storage.write(
        key: sessionKey,
        value: sessionValue,
      );

      _enabled = true;

      notifyListeners();
    } catch (e) {
      throw 'Failed to save session key: $e';
    }
  }

  Future<void> clearSession(String sessionKey) async {
    try {
      await _storage.delete(
        key: sessionKey,
      );

      _enabled = true;

      notifyListeners();
    } catch (e) {
      throw 'Failed to save session key: $e';
    }
  }

  Future<String?> getSession({
    required String sessionKey,
    bool requireAuth = true,
    String reason = 'Please authenticate to access your wallet',
  }) async {
    final value = await _storage.read(key: sessionKey);

    if (value == null) {
      return null;
    }

    _enabled = true;

    notifyListeners();

    return value;
  }
}
