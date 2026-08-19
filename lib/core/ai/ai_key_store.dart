import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raised when the encrypted store cannot persist a key. The key is still
/// usable through the mirror (see [AiKeyStore]), so callers can surface the
/// trouble honestly without pretending the key is invalid. Throwing (rather
/// than swallowing) lets the UI tell the reader that verification truly
/// succeeded but secure storage had trouble.
class KeyStorageException implements Exception {
  final String detail;

  const KeyStorageException(this.detail);

  @override
  String toString() => 'KeyStorageException: $detail';
}

/// Stores an optional user-supplied Google AI key so the Study feature can
/// scale beyond the bundled free-tier key.
///
/// Reliability contract: a key the reader verified and saved must never be
/// *silently* forgotten. The encrypted platform store (flutter_secure_storage
/// v10, whose Android backend replaces the deprecated Jetpack-Security cipher
/// that failed with `BadPaddingException` on many devices) is the primary
/// store; a plain app-private SharedPreferences mirror keeps a backup copy so
/// a later secure-storage fault cannot erase the reader's choice. All failures
/// are logged — nothing is swallowed to a quiet `null`.
class AiKeyStore {
  static const _keyName = 'beslet_quiet_guide_user_key';
  static const _mirrorKeyName = 'beslet_quiet_guide_user_key_mirror';
  static const _storage = FlutterSecureStorage();

  /// Optional injection points for tests. When null, the real plugin is used.
  final Future<String?> Function(String key)? readOverride;
  final Future<void> Function(String key, String value)? writeOverride;
  final Future<void> Function(String key)? deleteOverride;

  const AiKeyStore({
    this.readOverride,
    this.writeOverride,
    this.deleteOverride,
  });

  /// Returns the user's own key, or null when none is stored. Uses the
  /// encrypted store first, then the mirror, and logs every path.
  Future<String?> readUserKey() async {
    try {
      final secure = await (readOverride?.call(_keyName) ??
          _storage.read(key: _keyName));
      if (secure != null && secure.trim().isNotEmpty) {
        developer.log(
            'study: user key read from secure storage (${secure.trim().length} chars)',
            name: 'study');
        return secure.trim();
      }
      if (secure != null) {
        developer.log('study: secure storage had an empty key', name: 'study');
      }
    } catch (e) {
      developer.log('study: secure-storage read failed: $e',
          name: 'study', error: e);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final mirror = prefs.getString(_mirrorKeyName);
      if (mirror != null && mirror.trim().isNotEmpty) {
        developer.log(
            'study: user key read from mirror fallback '
            '(${mirror.trim().length} chars)',
            name: 'study');
        return mirror.trim();
      }
    } catch (e) {
      developer.log('study: mirror read failed: $e', name: 'study', error: e);
    }
    developer.log('study: no user key found', name: 'study');
    return null;
  }

  /// Stores the key in both the encrypted store and the mirror. The mirror is
  /// written first so a verified key can never be lost to a secure-storage
  /// fault. Throws [KeyStorageException] when the encrypted write fails so the
  /// caller can say so honestly — the key still works through the mirror.
  Future<void> saveUserKey(String key) async {
    final value = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mirrorKeyName, value);
    } catch (e) {
      developer.log('study: mirror write failed: $e', name: 'study', error: e);
    }
    try {
      await (writeOverride?.call(_keyName, value) ??
          _storage.write(key: _keyName, value: value));
      developer.log('study: user key saved to secure storage', name: 'study');
    } catch (e) {
      developer.log(
          'study: secure-storage write failed (mirror retained): $e',
          name: 'study',
          error: e);
      throw KeyStorageException('$e');
    }
  }

  /// Removes the key from both stores.
  Future<void> clearUserKey() async {
    try {
      await (deleteOverride?.call(_keyName) ?? _storage.delete(key: _keyName));
    } catch (e) {
      developer.log('study: secure-storage delete failed: $e',
          name: 'study', error: e);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mirrorKeyName);
    } catch (e) {
      developer.log('study: mirror delete failed: $e', name: 'study', error: e);
    }
    developer.log('study: user key cleared', name: 'study');
  }
}