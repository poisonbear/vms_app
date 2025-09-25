
/// 수치 관련 상수
class NumericConstants {
  NumericConstants._();

  // ============ 속도 관련 ============
  static const double movingSpeedThreshold = 0.5;
  static const double highSpeedThreshold = 20.0;
  static const double stoppedSpeedThreshold = 0.5;

  // ============ 좌표 관련 ============
  static const double latitudeMin = -90.0;
  static const double latitudeMax = 90.0;
  static const double longitudeMin = -180.0;
  static const double longitudeMax = 180.0;

  // ============ 파일 크기 ============
  static const int bytesPerKB = 1024;
  static const int warningFileSizeKB = 100;

  // ============ HTTP 상태 코드 ============
  static const int httpStatusOk = 200;
  static const int httpStatusUnauthorized = 401;
  static const int httpStatusForbidden = 403;
  static const int httpStatusNotFound = 404;
  static const int httpStatusInternalServerError = 500;

  // ============ 기타 ============
  static const int zeroValue = 0;
  static const int oneValue = 1;
  static const double halfValue = 0.5;
}
