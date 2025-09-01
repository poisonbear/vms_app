/// 검증 관련 상수
class ValidationConstants {
  ValidationConstants._();

  // ============ 길이 제한 ============
  static const int idMinLength = 8;
  static const int idMaxLength = 12;
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 20;
  static const int phoneLength = 11;
  static const int mmsiLength = 9;
  
  // ============ 정규식 패턴 ============
  static const String idPattern = r'^[a-zA-Z0-9]{8,12}$';
  static const String passwordPattern = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]';
  static const String mmsiPattern = r'^\d{9}$';
  static const String phonePattern = r'^\d{11}$';
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // ============ 특수 문자 ============
  static const String specialCharacters = r'[@$!%*?&":{}|<>]';
  
  // ============ 파일 크기 제한 ============
  static const int maxImageFileSizeKB = 100;
  static const int maxImageFileSizeBytes = 100 * 1024;
  
  // ============ 응답 값 ============
  static const int idAvailable = 0;
  static const int idNotAvailable = 1;
  
  // ============ 디버그 상수 ============
  static const int debugDecimalPlaces = 2;
}
