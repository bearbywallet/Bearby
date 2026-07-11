import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:bearby/config/storage_keys.dart';
import 'package:bearby/config/whitebird.dart';
import 'package:bearby/src/rust/api/local_storage.dart';

/// Persists the WhiteBird identity + JWTs via [LocalStorageImpl].
///
/// Tokens are trusted for [WhiteBirdConfig.tokenTtl] (90 days); after that
/// [ensureLoaded] wipes them so the next swap re-runs the SDK login.
class WhiteBirdSession {
  WhiteBirdSession(this._storage);

  final LocalStorageImpl _storage;

  String? _externalClientId;
  String? _accessToken;
  String? _refreshToken;
  String? _clientId;
  bool _loaded = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// WhiteBird client uuid, learned from order history responses.
  String? get clientId => _clientId;

  bool get hasSession =>
      (_accessToken?.isNotEmpty ?? false) && (_refreshToken?.isNotEmpty ?? false);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _externalClientId =
        await _storage.get_(key: StorageKeys.whitebirdExternalClientId);
    _accessToken = await _storage.get_(key: StorageKeys.whitebirdAccessToken);
    _refreshToken = await _storage.get_(key: StorageKeys.whitebirdRefreshToken);
    _clientId = await _storage.get_(key: StorageKeys.whitebirdClientId);
    final savedAtRaw =
        await _storage.get_(key: StorageKeys.whitebirdTokensSavedAt);
    _loaded = true;

    final savedAtMs = int.tryParse(savedAtRaw ?? '');
    if (hasSession && _isExpired(savedAtMs)) {
      debugPrint('[WhiteBirdSession] tokens older than TTL — clearing');
      await clearTokens();
    }
  }

  static bool _isExpired(int? savedAtMs) {
    if (savedAtMs == null) return true;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    return DateTime.now().difference(savedAt) > WhiteBirdConfig.tokenTtl;
  }

  /// Stable install-wide external client id for WhiteBird mapping.
  Future<String> ensureExternalClientId() async {
    await ensureLoaded();
    final existing = _externalClientId;
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateClientId();
    _externalClientId = id;
    await _storage.set_(key: StorageKeys.whitebirdExternalClientId, value: id);
    return id;
  }

  static String _generateClientId() {
    final random = Random.secure();
    final buffer = StringBuffer('bearby-');
    for (var i = 0; i < 16; i++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? email,
  }) async {
    await ensureLoaded();
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.set_(
        key: StorageKeys.whitebirdAccessToken, value: accessToken);
    await _storage.set_(
        key: StorageKeys.whitebirdRefreshToken, value: refreshToken);
    await _storage.set_(
      key: StorageKeys.whitebirdTokensSavedAt,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    if (email != null && email.isNotEmpty) {
      await _storage.set_(key: StorageKeys.whitebirdEmail, value: email);
    }
  }

  Future<void> saveClientId(String id) async {
    if (id.isEmpty || id == _clientId) return;
    _clientId = id;
    await _storage.set_(key: StorageKeys.whitebirdClientId, value: id);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.rm(key: StorageKeys.whitebirdAccessToken);
    await _storage.rm(key: StorageKeys.whitebirdRefreshToken);
    await _storage.rm(key: StorageKeys.whitebirdTokensSavedAt);
  }
}
