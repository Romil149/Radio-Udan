import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence for bearer token and profile fields used at cold start.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _keyToken = 'auth_token';
  static const _keyPhone = 'phone_e164';
  static const _keyEmail = 'auth_email';
  static const _keyName = 'auth_name';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _keyToken);

  Future<String?> readPhone() => _storage.read(key: _keyPhone);

  Future<String?> readEmail() => _storage.read(key: _keyEmail);

  Future<String?> readName() => _storage.read(key: _keyName);

  Future<void> saveSession({
    required String token,
    required String phoneE164,
    String? email,
    String? name,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyPhone, value: phoneE164);
    if (email != null) {
      await _storage.write(key: _keyEmail, value: email);
    }
    if (name != null) {
      await _storage.write(key: _keyName, value: name);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyPhone);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyName);
  }
}
