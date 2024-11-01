import 'package:zilpay/services/secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthGuard extends ChangeNotifier {
  final SecureStorage _secureStorage = SecureStorage();

  bool _ready = false;
  bool _enabled = false;

  bool get ready => _ready;
  bool get enabled => _enabled;

  Future<void> setSession(String key) async {
    await _secureStorage.saveSessionKey(key);

    _enabled = true;
    _ready = true;

    notifyListeners();
  }

  Future<String> getSession() async {
    String? key = await _secureStorage.getSessionKey(
      reason: 'Please authenticate to unlock your wallet',
    );

    if (key == null) {
      throw StorageException('Session key is empty');
    }

    _enabled = true;

    notifyListeners();

    return key;
  }

  Future<void> initialize() async {
    _enabled = false;
    _ready = false;

    notifyListeners();
  }
}
