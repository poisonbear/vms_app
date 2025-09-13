/// 앱 전역 설정 상수
class AppConfig {
  AppConfig._();

  // 앱 정보
  static const String appName = 'K-VMS';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // 타임아웃 설정 (밀리초)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 100000;
  static const int sendTimeout = 30000;

  // 페이징 설정
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 캐시 설정
  static const Duration cacheValidDuration = Duration(hours: 1);
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB

  // 재시도 설정
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // 날짜 형식
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String timeFormat = 'HH:mm:ss';

  // 권한 역할
  static const String roleAdmin = 'ROLE_ADMIN';
  static const String roleUser = 'ROLE_USER';
  static const String roleManager = 'ROLE_MANAGER';
}

/// 정규식 패턴
class AppPatterns {
  AppPatterns._();

  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phone = RegExp(
    r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$',
  );
  static final RegExp mmsi = RegExp(
    r'^\d{9}$',
  );
}
