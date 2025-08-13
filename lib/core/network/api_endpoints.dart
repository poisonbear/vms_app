// lib/core/network/api_endpoints.dart
class ApiEndpoints {
  // 선박 관련 엔드포인트
  static const String vesselList = '/api/vessel/list';
  static const String vesselDetails = '/api/vessel/details';
  static const String vesselRoute = '/api/vessel/route';
  static const String vesselPositions = '/api/vessel/positions';
  static const String vesselSearch = '/api/vessel/search';

  // 인증 관련 엔드포인트
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String checkUserId = '/api/auth/check-userid';
  static const String terms = '/api/auth/terms';

  // 항행 관련 엔드포인트
  static const String navigationHistory = '/api/navigation/history';
  static const String navigationWarnings = '/api/navigation/warnings';

  // 날씨 관련 엔드포인트
  static const String weatherInfo = '/api/weather/info';
  static const String weatherList = '/api/weather/list';

  // 동적 ID를 포함한 엔드포인트 생성
  static String withId(String endpoint, dynamic id) {
    return '$endpoint/$id';
  }

  // 쿼리 파라미터가 포함된 엔드포인트 생성
  static String withQuery(String endpoint, Map<String, dynamic> params) {
    if (params.isEmpty) return endpoint;

    final query = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    return '$endpoint?$query';
  }
}