// lib/core/utils/password_utils.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  PasswordUtils._();

  /// 비밀번호 해싱 (웹과 동일한 방식)
  /// 원본 → SHA256 (Hex) → Base64
  static String hash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final hexString = digest.toString();
    final hexBytes = utf8.encode(hexString);
    return base64.encode(hexBytes);
  }
}
