// lib/core/constants/validation_rules.dart

/// 검증 규칙 통합 클래스 (상수 + 패턴 + 메서드)
class ValidationRules {
  ValidationRules._();

  // ============================================
  // ID 검증
  // ============================================
  static const int idMinLength = 8;
  static const int idMaxLength = 20;
  static const String idPattern = r'^[a-zA-Z0-9]{8,20}$';
  static final RegExp idRegExp = RegExp(idPattern);
  static bool isValidId(String value) => idRegExp.hasMatch(value);

  // ============================================
  // 비밀번호 검증
  // ============================================
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 20;

  // 단순 패턴 (영문, 숫자, 특수문자 허용)
  static const String passwordSimplePattern =
      r'^[a-zA-Z0-9!@#$%^&*(),.?":{}|<>]{6,12}$';

  // 복잡한 패턴 (영문+숫자+특수문자 필수)
  static const String passwordComplexPattern =
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[a-zA-Z\d!@#$%^&*(),.?":{}|<>]{6,12}$';

  static final RegExp passwordSimpleRegExp = RegExp(passwordSimplePattern);
  static final RegExp passwordComplexRegExp = RegExp(passwordComplexPattern);

  // 구성 요소 확인용
  static const String letterPattern = r'[a-zA-Z]';
  static const String numberPattern = r'[0-9]';
  static const String specialCharPattern = r'[!@#$%^&*(),.?":{}|<>]';

  static final RegExp letterRegExp = RegExp(letterPattern);
  static final RegExp numberRegExp = RegExp(numberPattern);
  static final RegExp specialCharRegExp = RegExp(specialCharPattern);

  static bool isValidPassword(String value) =>
      passwordSimpleRegExp.hasMatch(value);
  static bool isValidComplexPassword(String value) =>
      passwordComplexRegExp.hasMatch(value);

  static bool hasLetter(String value) => letterRegExp.hasMatch(value);
  static bool hasNumber(String value) => numberRegExp.hasMatch(value);
  static bool hasSpecialChar(String value) => specialCharRegExp.hasMatch(value);

  // ============================================
  // MMSI 검증
  // ============================================
  static const int mmsiLength = 9;
  static const String mmsiPattern = r'^\d{9}$';
  static final RegExp mmsiRegExp = RegExp(mmsiPattern);
  static bool isValidMmsi(String value) => mmsiRegExp.hasMatch(value);

  // ============================================
  // 전화번호 검증
  // ============================================
  static const int phoneLength = 11;
  static const String phonePattern = r'^\d{11}$';
  static const String phoneFormatPattern = r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$';

  static final RegExp phoneRegExp = RegExp(phonePattern);
  static final RegExp phoneFormatRegExp = RegExp(phoneFormatPattern);

  static bool isValidPhone(String value) {
    return phoneRegExp.hasMatch(value) || phoneFormatRegExp.hasMatch(value);
  }

  // ============================================
  // 이메일 검증
  // ============================================
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static final RegExp emailRegExp = RegExp(emailPattern);
  static bool isValidEmail(String value) => emailRegExp.hasMatch(value);

  // ============================================
  // 파일 크기 제한
  // ============================================
  static const int maxImageFileSizeKB = 100;
  static const int maxImageFileSizeBytes = 100 * 1024;

  // ============================================
  // API 응답 값
  // ============================================
  static const int idAvailable = 0;
  static const int idNotAvailable = 1;

  // ============================================
  // 디버그 상수
  // ============================================
  static const int debugDecimalPlaces = 2;

  // ============================================
  // 추가 유용한 패턴
  // ============================================
  static const String urlPattern =
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$';
  static const String ipAddressPattern =
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';
  static const String koreanPattern = r'^[가-힣]+$';
  static const String englishPattern = r'^[a-zA-Z]+$';
  static const String alphanumericPattern = r'^[a-zA-Z0-9]+$';
  static const String hexColorPattern = r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$';

  static final RegExp urlRegExp = RegExp(urlPattern);
  static final RegExp ipAddressRegExp = RegExp(ipAddressPattern);
  static final RegExp koreanRegExp = RegExp(koreanPattern);
  static final RegExp englishRegExp = RegExp(englishPattern);
  static final RegExp alphanumericRegExp = RegExp(alphanumericPattern);
  static final RegExp hexColorRegExp = RegExp(hexColorPattern);

  static bool isValidUrl(String value) => urlRegExp.hasMatch(value);
  static bool isValidIpAddress(String value) => ipAddressRegExp.hasMatch(value);
  static bool isKorean(String value) => koreanRegExp.hasMatch(value);
  static bool isEnglish(String value) => englishRegExp.hasMatch(value);
  static bool isAlphanumeric(String value) =>
      alphanumericRegExp.hasMatch(value);
  static bool isValidHexColor(String value) => hexColorRegExp.hasMatch(value);
}
