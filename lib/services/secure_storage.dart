import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const String _keyPrefix = 'zilpay_';
  static const String _sessionKey = '${_keyPrefix}session';

  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: true,
          ),
        );

  Future<void> saveSessionKey(String sessionKey) async {
    try {
      final encodedKey = base64.encode(utf8.encode(sessionKey));

      await _storage.write(
        key: _sessionKey,
        value: encodedKey,
      );
    } catch (e) {
      throw StorageException('Failed to save session key: $e');
    }
  }

  Future<String?> getSessionKey() async {
    try {
      final encodedKey = await _storage.read(key: _sessionKey);
      if (encodedKey == null) return null;

      return utf8.decode(base64.decode(encodedKey));
    } catch (e) {
      throw StorageException('Failed to get session key: $e');
    }
  }

  Future<bool> hasSessionKey() async {
    try {
      final key = await _storage.read(key: _sessionKey);
      return key != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteSessionKey() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (e) {
      throw StorageException('Failed to delete session key: $e');
    }
  }

  Future<void> clearStorage() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to clear storage: $e');
    }
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => message;
}
