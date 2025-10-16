// lib/core/utils/validation/validators.dart

import 'package:vms_app/core/constants/validation_rules.dart';

/// 유효성 검사 유틸리티
class Validators {
  Validators._();

  /// 이메일 검증
  static bool isValidEmail(String email) {
    return ValidationRules.isValidEmail(email);
  }

  /// 전화번호 검증
  static bool isValidPhone(String phone) {
    return ValidationRules.isValidPhone(phone);
  }

  /// 비밀번호 검증 (단순)
  static bool isValidPassword(String password) {
    return ValidationRules.isValidPassword(password);
  }

  /// 비밀번호 검증 (복잡 - 영문+숫자+특수문자 필수)
  static bool isValidComplexPassword(String password) {
    return ValidationRules.isValidComplexPassword(password);
  }

  /// MMSI 검증
  static bool isValidMmsi(String mmsi) {
    return ValidationRules.isValidMmsi(mmsi);
  }

  /// 아이디 검증
  static bool isValidId(String id) {
    return ValidationRules.isValidId(id);
  }

  /// URL 검증
  static bool isValidUrl(String url) {
    return ValidationRules.isValidUrl(url);
  }

  /// IP 주소 검증
  static bool isValidIpAddress(String ip) {
    return ValidationRules.isValidIpAddress(ip);
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

  /// 한글만 포함 검증
  static bool isKorean(String value) {
    return ValidationRules.isKorean(value);
  }

  /// 영문만 포함 검증
  static bool isAlphabetic(String value) {
    return ValidationRules.isEnglish(value);
  }

  /// 영숫자만 포함 검증
  static bool isAlphanumeric(String value) {
    return ValidationRules.isAlphanumeric(value);
  }

  /// HEX 색상 코드 검증
  static bool isValidHexColor(String value) {
    return ValidationRules.isValidHexColor(value);
  }

  // ============================================
  // 비밀번호 구성 요소 검증
  // ============================================

  /// 영문 포함 여부
  static bool hasLetter(String value) {
    return ValidationRules.hasLetter(value);
  }

  /// 숫자 포함 여부
  static bool hasNumber(String value) {
    return ValidationRules.hasNumber(value);
  }

  /// 특수문자 포함 여부
  static bool hasSpecialChar(String value) {
    return ValidationRules.hasSpecialChar(value);
  }
}
