import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento SEGURO solo para flags locales (NO contraseñas, NO tokens).
class SecureStore {
  // iOS: Keychain  |  Android: EncryptedSharedPreferences
  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const privacyAcceptedKey = 'privacy_accepted';

  static Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);

  static Future<String?> read(String key) => _s.read(key: key);

  static Future<void> delete(String key) => _s.delete(key: key);

  static Future<void> clearAll() => _s.deleteAll();

  // Helpers
  static Future<void> setPrivacyAccepted(bool accepted) =>
      write(privacyAcceptedKey, accepted ? '1' : '0');

  static Future<bool> isPrivacyAccepted() async =>
      (await read(privacyAcceptedKey)) == '1';
}
