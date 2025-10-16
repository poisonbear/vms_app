/// 네트워크 관련 상수
class NetworkConstants {
  NetworkConstants._();

  // ============ User-Agent ============
  static const String userAgent = 'VMS-App/1.0';

  // ============ Headers ============
  static const Map<String, String> defaultHeaders = {
    'ngrok-skip-browser-warning': '100',
  };

  // ============ 재시도 설정 ============
  static const int maxRetryAttempts = 3;
  // Duration은 AppDurations.seconds2 또는 AppDurations.retryDelay 사용

  // ============ 페이지네이션 ============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 10;

  // ============ 캐시 설정 ============
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int maxCacheAge = 3600; // 1시간 (초 단위)

  // ============ HTTP 메서드 ============
  static const String methodGet = 'GET';
  static const String methodPost = 'POST';
  static const String methodPut = 'PUT';
  static const String methodDelete = 'DELETE';
  static const String methodPatch = 'PATCH';

  // ============ Content-Type ============
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlEncoded =
      'application/x-www-form-urlencoded';
  static const String contentTypeMultipart = 'multipart/form-data';

  // ============ API 버전 ============
  static const String apiVersion = 'v1';

  // ============ 네트워크 품질 임계값 ============
  static const double poorNetworkThreshold = 150.0; // Kbps
  static const double moderateNetworkThreshold = 500.0; // Kbps
  static const double goodNetworkThreshold = 1000.0; // Kbps
}
