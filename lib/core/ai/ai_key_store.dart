import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores an optional user-supplied Google AI key so the Quiet Guide can scale
/// beyond the bundled free-tier key. Stored in the OS keychain / encrypted
/// prefs. The bundled key is always the fallback.
class AiKeyStore {
  static const _keyName = 'beslet_quiet_guide_user_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Returns the user's own key, or null if none was saved.
  Future<String?> readUserKey() async {
    try {
      return await _storage.read(key: _keyName);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserKey(String key) async {
    await _storage.write(key: _keyName, value: key.trim());
  }

  Future<void> clearUserKey() async {
    await _storage.delete(key: _keyName);
  }
}
