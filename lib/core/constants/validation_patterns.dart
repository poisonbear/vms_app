import 'package:vms_app/core/constants/validation_constants.dart';

/// 정규식 패턴 상수 클래스
class ValidationPatterns {
  ValidationPatterns._();

  // ============ 기본 패턴 문자열 ============
  static const String idPattern = r'^[a-zA-Z0-9]{8,12}$';
  static const String mmsiPattern = r'^\d{9}$';
  static const String phonePattern = r'^\d{11}$';
  static const String phoneFormatPattern = r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$';
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // ============ 비밀번호 구성 요소 패턴 ============
  static const String letterPattern = r'[a-zA-Z]';
  static const String numberPattern = r'[0-9]';
  static const String specialCharPattern = r'[!@#$%^&*(),.?":{}|<>]';

  // ============ 복합 비밀번호 패턴 ============
  static const String passwordComplexPattern =
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[a-zA-Z\d!@#$%^&*(),.?":{}|<>]{6,12}$';

  // ============ 컴파일된 RegExp 객체들 ============
  static final RegExp idRegExp = RegExp(idPattern);
  static final RegExp mmsiRegExp = RegExp(mmsiPattern);
  static final RegExp phoneRegExp = RegExp(phonePattern);
  static final RegExp phoneFormatRegExp = RegExp(phoneFormatPattern);
  static final RegExp emailRegExp = RegExp(emailPattern);

  static final RegExp letterRegExp = RegExp(letterPattern);
  static final RegExp numberRegExp = RegExp(numberPattern);
  static final RegExp specialCharRegExp = RegExp(specialCharPattern);
  static final RegExp passwordComplexRegExp = RegExp(passwordComplexPattern);

  // ============ 헬퍼 메서드들 ============
  /// 아이디 유효성 검증
  static bool isValidId(String id) => idRegExp.hasMatch(id);

  /// MMSI 유효성 검증
  static bool isValidMmsi(String mmsi) => mmsiRegExp.hasMatch(mmsi);

  /// 전화번호 유효성 검증 (11자리)
  static bool isValidPhone(String phone) => phoneRegExp.hasMatch(phone);

  /// 전화번호 유효성 검증 (형식 포함)
  static bool isValidPhoneFormat(String phone) =>
      phoneFormatRegExp.hasMatch(phone);

  /// 이메일 유효성 검증
  static bool isValidEmail(String email) => emailRegExp.hasMatch(email);

  /// 비밀번호 구성 요소 검증
  static bool hasLetter(String password) => letterRegExp.hasMatch(password);
  static bool hasNumber(String password) => numberRegExp.hasMatch(password);
  static bool hasSpecialChar(String password) =>
      specialCharRegExp.hasMatch(password);

  /// 복합 비밀번호 검증 (6-12자리, 영문+숫자+특수문자)
  static bool isValidPassword(String password) {
    if (password.length < ValidationConstants.passwordMinLength ||
        password.length > ValidationConstants.passwordMaxLength) {
      return false;
    }
    return hasLetter(password) &&
        hasNumber(password) &&
        hasSpecialChar(password);
  }

  /// 상세한 비밀번호 검증 결과
  static Map<String, bool> validatePasswordDetails(String password) {
    return {
      'hasValidLength':
          password.length >= ValidationConstants.passwordMinLength &&
              password.length <= ValidationConstants.passwordMaxLength,
      'hasLetter': hasLetter(password),
      'hasNumber': hasNumber(password),
      'hasSpecialChar': hasSpecialChar(password),
      'isValid': isValidPassword(password),
    };
  }
}

/// 추가 검증 헬퍼 클래스
class ValidationHelper {
  ValidationHelper._();

  /// 아이디 검증 (간단한 방법)
  static bool validateIdSimple(String id) {
    return ValidationPatterns.isValidId(id);
  }

  /// 아이디 검증 (세부적인 방법)
  static Map<String, bool> validateIdDetailed(String id) {
    return {
      'hasValidLength': id.length >= ValidationConstants.idMinLength &&
          id.length <= ValidationConstants.idMaxLength,
      'hasOnlyAlphanumeric': ValidationPatterns.idRegExp.hasMatch(id),
      'isValid': ValidationPatterns.isValidId(id),
    };
  }

  /// 빈 문자열이 아닌 경우에만 패턴 검증
  static bool validateIfNotEmpty(
      String value, bool Function(String) validator) {
    return value.isEmpty || validator(value);
  }
}
