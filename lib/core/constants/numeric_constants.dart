// lib/core/constants/numeric_constants.dart

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

  // ============ 각도 관련 (풍향 계산용) ============
  static const int i30 = 30;
  static const int i180 = 180;
  static const int i360 = 360;

  // ============ 풍향 8방위 각도 ============
  static const double d22_5 = 22.5;
  static const double d67_5 = 67.5;
  static const double d112_5 = 112.5;
  static const double d157_5 = 157.5;
  static const double d202_5 = 202.5;
  static const double d247_5 = 247.5;
  static const double d292_5 = 292.5;
  static const double d337_5 = 337.5;
}
