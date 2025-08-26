import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 엔드포인트 중앙 관리
class ApiEndpoints {
  ApiEndpoints._();

  // Base URLs
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';

  // 인증 관련
  static String get authLogin => '$baseUrl/auth/login';
  static String get authLogout => '$baseUrl/auth/logout';
  static String get authRegister => '$baseUrl/auth/register';
  static String get authRefresh => '$baseUrl/auth/refresh';

  // 약관 관련
  static String get termsList => _getEndpoint('CMD_SELECT_TERMS');
  static String get termsDetail => _getEndpoint('CMD_GET_TERMS');
  static String get termsAgree => _getEndpoint('CMD_AGREE_TERMS');

  // 항행 이력 관련
  static String get navigationHistory =>
      _getEndpoint('kdn_ros_select_navigation_Info');
  static String get navigationVisibility =>
      _getEndpoint('kdn_ros_select_visibility_Info');
  static String get navigationWarnings =>
      _getEndpoint('kdn_ros_select_navigation_warn_Info');

  // 선박 관련
  static String get vesselSearch => _getEndpoint('kdn_gis_select_vessel_Info');
  static String get vesselRoute => _getEndpoint('kdn_gis_select_vessel_Route');
  static String get vesselRealtime =>
      _getEndpoint('kdn_gis_select_vessel_Realtime');

  // 헬퍼 메서드
  static String _getEndpoint(String key) {
    final endpoint = dotenv.env[key];
    if (endpoint == null) {
      print('Warning: API endpoint $key not found in .env');
    }
    return endpoint ?? '';
  }
}
