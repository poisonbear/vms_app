import 'dart:convert';

/// 간단한 암호화 유틸리티 (Base64 인코딩)
/// 실제 암호화가 필요한 경우 encrypt 패키지 사용 권장
class SimpleEncryption {
  /// 문자열 인코딩
  static String encode(String plainText) {
    final bytes = utf8.encode(plainText);
    return base64.encode(bytes);
  }
  
  /// 문자열 디코딩
  static String decode(String encodedText) {
    final bytes = base64.decode(encodedText);
    return utf8.decode(bytes);
  }
  
  /// JSON 인코딩
  static String encodeJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encode(jsonString);
  }
  
  /// JSON 디코딩
  static Map<String, dynamic> decodeJson(String encodedData) {
    final jsonString = decode(encodedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  /// 간단한 마스킹
  static String mask(String text, {int visibleChars = 4}) {
    if (text.length <= visibleChars * 2) {
      return '*' * text.length;
    }
    final start = text.substring(0, visibleChars);
    final end = text.substring(text.length - visibleChars);
    final masked = '*' * (text.length - visibleChars * 2);
    return '$start$masked$end';
  }
}
