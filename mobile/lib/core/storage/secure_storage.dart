import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enveloppe autour de flutter_secure_storage, qui s'appuie sur
/// l'Android Keystore et l'iOS Keychain (section 9 du cahier des charges).
/// Ne JAMAIS stocker les tokens JWT ou clés de chiffrement autrement
/// qu'à travers cette classe.
class SecureStorage {
  SecureStorage._internal();
  static final SecureStorage instance = SecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserRole = 'user_role';
  static const _kUserId = 'user_id';
  static const _kEncryptionKey = 'local_encryption_key';
  static const _kDeviceIdentifier = 'device_identifier';
  static const _kCustomBaseUrl = 'custom_base_url';

  Future<void> saveBaseUrl(String url) =>
      _storage.write(key: _kCustomBaseUrl, value: url);
  Future<String?> get baseUrl => _storage.read(key: _kCustomBaseUrl);
  Future<void> clearBaseUrl() => _storage.delete(key: _kCustomBaseUrl);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _kAccessToken, value: access);
    await _storage.write(key: _kRefreshToken, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _kRefreshToken);

  Future<void> saveRole(String role) =>
      _storage.write(key: _kUserRole, value: role);
  Future<String?> get role => _storage.read(key: _kUserRole);

  Future<void> saveUserId(int id) =>
      _storage.write(key: _kUserId, value: id.toString());
  Future<String?> get userId => _storage.read(key: _kUserId);

  Future<String?> get encryptionKey => _storage.read(key: _kEncryptionKey);
  Future<void> saveEncryptionKey(String key) =>
      _storage.write(key: _kEncryptionKey, value: key);

  Future<String> getOrCreateDeviceIdentifier() async {
    final existing = await _storage.read(key: _kDeviceIdentifier);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final identifier = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: _kDeviceIdentifier, value: identifier);
    return identifier;
  }

  /// Purge complète à la déconnexion / changement d'appareil.
  Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserRole);
    await _storage.delete(key: _kUserId);
    // La clé de chiffrement locale n'est volontairement PAS supprimée ici :
    // elle reste nécessaire pour déchiffrer les fichiers déjà téléchargés.
  }
}
