import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../storage/secure_storage.dart';

/// Chiffrement local AES des fichiers téléchargés (section 26-27).
///
/// RÈGLES RESPECTÉES :
/// - la clé n'est jamais hardcodée dans le code ;
/// - la clé est générée aléatoirement puis stockée UNIQUEMENT via
///   SecureStorage (Android Keystore / iOS Keychain) ;
/// - le PDF en clair n'est jamais écrit dans un dossier public
///   (Downloads, galerie...), seulement dans le stockage privé de l'app.
class LocalEncryptionService {
  LocalEncryptionService._();
  static final instance = LocalEncryptionService._();

  Future<enc.Key> _getOrCreateKey() async {
    final existing = await SecureStorage.instance.encryptionKey;
    if (existing != null) {
      return enc.Key.fromBase64(existing);
    }
    final newKey = enc.Key.fromSecureRandom(32); // AES-256
    await SecureStorage.instance.saveEncryptionKey(newKey.base64);
    return newKey;
  }

  Future<File> encryptToFile({required Uint8List plainBytes, required File destination}) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    // On préfixe le fichier chiffré par l'IV (nécessaire, non secret) pour le déchiffrement.
    final output = BytesBuilder()
      ..add(iv.bytes)
      ..add(encrypted.bytes);
    await destination.writeAsBytes(output.toBytes(), flush: true);
    return destination;
  }

  Future<Uint8List> decryptFromFile(File encryptedFile) async {
    final key = await _getOrCreateKey();
    final raw = await encryptedFile.readAsBytes();
    final iv = enc.IV(raw.sublist(0, 16));
    final cipherBytes = raw.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  /// Empreinte non réversible utile pour nommer les fichiers chiffrés
  /// sans exposer d'information sur leur contenu.
  String fileNameHash(String seed) => sha256.convert(utf8.encode(seed)).toString();
}
