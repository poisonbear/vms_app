import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 암호화 관련 유틸리티
class CryptoUtils {
  /// 비밀번호를 SHA256으로 해시화
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// 비밀번호를 해시화하고 Base64로 인코딩
  static String hashAndEncode(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }
}