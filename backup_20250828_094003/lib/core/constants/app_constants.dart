class AppConstants {
  // API 설정
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryCount = 3;
  
  // 지도 설정
  static const double mapDefaultZoom = 13.0;
  static const double mapMinZoom = 5.0;
  static const double mapMaxZoom = 18.0;
  
  // 페이지네이션
  static const int defaultPageSize = 20;
  
  // 캐시
  static const Duration cacheExpiration = Duration(hours: 1);
}
