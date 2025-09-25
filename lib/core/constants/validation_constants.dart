/// 검증 관련 상수 (수치 및 응답 값)
class ValidationConstants {
  ValidationConstants._();

  // ============ 길이 제한 ============
  static const int idMinLength = 8;
  static const int idMaxLength = 12;
  static const int passwordMinLength = 6; // 기존 8에서 6으로 변경 (실제 사용에 맞춤)
  static const int passwordMaxLength = 12; // 기존 20에서 12로 변경 (실제 사용에 맞춤)
  static const int phoneLength = 11;
  static const int mmsiLength = 9;

  // ============ 파일 크기 제한 ============
  static const int maxImageFileSizeKB = 100;
  static const int maxImageFileSizeBytes = 100 * 1024;

  // ============ 응답 값 ============
  static const int idAvailable = 0;
  static const int idNotAvailable = 1;

  // ============ 디버그 상수 ============
  static const int debugDecimalPlaces = 2;
}
