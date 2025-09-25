/// 정규식 패턴 상수 클래스
class ValidationPatterns {
  ValidationPatterns._();

  // ============ 기본 패턴 문자열 ============
  static const String idPattern = r'^[a-zA-Z0-9]{8,12}$';
  static const String mmsiPattern = r'^\d{9}$';
  static const String phonePattern = r'^\d{11}$';
  static const String phoneFormatPattern = r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$';
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // ============ 비밀번호 구성 요소 패턴 ============
  static const String letterPattern = r'[a-zA-Z]';
  static const String numberPattern = r'[0-9]';
  static const String specialCharPattern = r'[!@#$%^&*(),.?":{}|<>]';

  // ============ 복합 비밀번호 패턴 ============
  static const String passwordComplexPattern =
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[a-zA-Z\d!@#$%^&*(),.?":{}|<>]{6,12}$';

  static const String passwordSimplePattern = r'^[a-zA-Z0-9!@#$%^&*(),.?":{}|<>]{6,12}$';

  // ============ RegExp 객체 (컴파일된 패턴) ============
  static final RegExp idRegExp = RegExp(idPattern);
  static final RegExp mmsiRegExp = RegExp(mmsiPattern);
  static final RegExp phoneRegExp = RegExp(phonePattern);
  static final RegExp phoneFormatRegExp = RegExp(phoneFormatPattern);
  static final RegExp emailRegExp = RegExp(emailPattern);
  static final RegExp letterRegExp = RegExp(letterPattern);
  static final RegExp numberRegExp = RegExp(numberPattern);
  static final RegExp specialCharRegExp = RegExp(specialCharPattern);
  static final RegExp passwordComplexRegExp = RegExp(passwordComplexPattern);
  static final RegExp passwordSimpleRegExp = RegExp(passwordSimplePattern);

  // ============ 추가 유용한 패턴들 ============
  static const String urlPattern = r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$';
  static const String ipAddressPattern = r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';
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

  // ============ 유효성 검증 헬퍼 메서드 ============
  static bool isValidId(String value) => idRegExp.hasMatch(value);
  static bool isValidMmsi(String value) => mmsiRegExp.hasMatch(value);
  static bool isValidPhone(String value) => phoneRegExp.hasMatch(value) || phoneFormatRegExp.hasMatch(value);
  static bool isValidEmail(String value) => emailRegExp.hasMatch(value);
  static bool isValidPassword(String value) => passwordSimpleRegExp.hasMatch(value);
  static bool isValidComplexPassword(String value) => passwordComplexRegExp.hasMatch(value);
  static bool isValidUrl(String value) => urlRegExp.hasMatch(value);
  static bool isValidIpAddress(String value) => ipAddressRegExp.hasMatch(value);
  static bool isKorean(String value) => koreanRegExp.hasMatch(value);
  static bool isEnglish(String value) => englishRegExp.hasMatch(value);
  static bool isAlphanumeric(String value) => alphanumericRegExp.hasMatch(value);
  static bool isValidHexColor(String value) => hexColorRegExp.hasMatch(value);
}