import 'package:vms_app/core/constants/constants.dart';

/// 유효성 검사 유틸리티
class Validators {
  Validators._();

  /// 이메일 검증
  static bool isValidEmail(String email) {
    return ValidationPatterns.isValidEmail(email);
  }

  /// 전화번호 검증
  static bool isValidPhone(String phone) {
    return ValidationPatterns.isValidPhone(phone);
  }

  /// 비밀번호 검증
  static bool isValidPassword(String password) {
    return ValidationPatterns.isValidPassword(password);
  }

  /// MMSI 검증
  static bool isValidMmsi(String mmsi) {
    return ValidationPatterns.isValidMmsi(mmsi);
  }

  /// 아이디 검증
  static bool isValidId(String id) {
    return ValidationPatterns.isValidId(id);
  }

  /// 비어있지 않은 문자열 검증
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// 최소 길이 검증
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// 최대 길이 검증
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  /// 숫자만 포함 검증
  static bool isNumeric(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value);
  }

  /// 영문만 포함 검증
  static bool isAlphabetic(String value) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(value);
  }

  /// 영숫자만 포함 검증
  static bool isAlphanumeric(String value) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
  }
}