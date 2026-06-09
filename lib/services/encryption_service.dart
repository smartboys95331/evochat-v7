import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // 32-char key — in production, generate & store per-device securely
  static final _key = enc.Key.fromUtf8('Ev0Ch4tS3cur3K3y!2024#XyZaBcDeFg');

  /// Encrypts text and prepends a random IV (base64 encoded, separated by ':')
  static String encryptText(String plainText) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Format: base64(iv):base64(ciphertext)
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts text that was encrypted with encryptText()
  static String decryptText(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;
      final iv = enc.IV(base64Decode(parts[0]));
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      return '[decryption error]';
    }
  }
}
