/// 네트워크 및 API 관련 상수
class NetworkConstants {
  NetworkConstants._();

  // ============ Timeouts (밀리초) ============
  static const int connectTimeoutMs = 30000; // 30초
  static const int receiveTimeoutMs = 100000; // 100초
  static const int sendTimeoutMs = 30000; // 30초

  // ============ Retry ============
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ============ API Response Codes ============
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusServerError = 500;

  // ============ Pagination ============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int initialPage = 1;
}
