import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zilpay/services/biometric_service.dart';

class SecureStorage {
  static const String _keyPrefix = 'zilpay_';
  static const String _sessionKey = '${_keyPrefix}session';
  static const String _authMethodKey = '${_keyPrefix}auth_method';

  final FlutterSecureStorage _storage;
  final AuthService _authService;

  SecureStorage({AuthService? authService})
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

  Future<void> saveSessionKey(String sessionKey) async {
    try {
      final authMethods = await _authService.getAvailableAuthMethods();

      if (authMethods.contains(AuthMethod.none)) {
        throw SecurityException(
            'Device does not support secure storage. Please enable device lock.');
      }

      final encodedKey = base64.encode(utf8.encode(sessionKey));

      await _storage.write(
        key: _sessionKey,
        value: encodedKey,
      );

      await _storage.write(
        key: _authMethodKey,
        value: authMethods.first.toString(),
      );
    } catch (e) {
      throw StorageException('Failed to save session key: $e');
    }
  }

  Future<String?> getSessionKey({
    bool requireAuth = true,
    String reason = 'Please authenticate to access your wallet',
  }) async {
    try {
      final encodedKey = await _storage.read(key: _sessionKey);
      if (encodedKey == null) return null;

      if (requireAuth) {
        final isAuthenticated = await _authService.authenticate(
          reason: reason,
        );

        if (!isAuthenticated) {
          throw AuthenticationException('Authentication failed');
        }
      }

      return utf8.decode(base64.decode(encodedKey));
    } catch (e) {
      if (e is AuthenticationException) rethrow;
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
      await _storage.delete(key: _authMethodKey);
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

  Future<AuthMethod> getCurrentAuthMethod() async {
    try {
      final method = await _storage.read(key: _authMethodKey);
      if (method == null) return AuthMethod.none;
      return AuthMethod.values.firstWhere(
        (e) => e.toString() == method,
        orElse: () => AuthMethod.none,
      );
    } catch (e) {
      return AuthMethod.none;
    }
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  @override
  String toString() => message;
}
