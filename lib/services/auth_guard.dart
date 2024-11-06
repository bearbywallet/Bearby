import 'package:zilpay/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthGuard extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  final AuthService _authService;

  bool _ready = false;
  bool _enabled = false; // TODO: remake it to many wallets

  bool get ready => _ready;
  bool get enabled => _enabled;

  AuthGuard({AuthService? authService})
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: true,
          ),
        ),
        _authService = authService ?? AuthService();

  Future<void> setSession(String sessionKey, String sessionValue) async {
    try {
      final authMethods = await _authService.getAvailableAuthMethods();

      if (authMethods.contains(AuthMethod.none)) {
        throw 'Device does not support secure storage. Please enable device lock.';
      }

      await _storage.write(
        key: sessionKey,
        value: sessionValue,
      );

      _enabled = true;
      _ready = true;

      notifyListeners();
    } catch (e) {
      throw 'Failed to save session key: $e';
    }
  }

  Future<String> getSession({
    required String sessionKey,
    bool requireAuth = true,
    String reason = 'Please authenticate to access your wallet',
  }) async {
    final value = await _storage.read(key: sessionKey);

    if (value == null) {
      throw 'Session key is empty';
    }

    _enabled = true;

    notifyListeners();

    return value;
  }

  Future<void> initialize(bool ready) async {
    _enabled = false;
    _ready = ready;

    notifyListeners();
  }
}
