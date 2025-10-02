import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// API 엔드포인트 중앙 관리 (수정된 버전)
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://118.40.116.129:8080';

  // ===== 인증 관련 =====
  static String get authLogin => dotenv.env['kdn_loginForm_key'] ?? '';
  static String get authRole => dotenv.env['kdn_usm_select_role_data_key'] ?? '';
  static String get authRegister => dotenv.env['kdn_usm_insert_membership_key'] ?? '';

  // ===== 회원 관련 =====
  static String get memberInfo => dotenv.env['kdn_usm_select_member_info_data'] ?? '';
  static String get updateMember => dotenv.env['kdn_usm_update_membership_key'] ?? '';
  static String get memberSearch => dotenv.env['kdn_usm_select_membership_search_key'] ?? '';

  // ===== 약관 =====
  static String get termsList => dotenv.env['kdn_usm_select_cmd_key'] ?? '';

  // ===== 선박 관련 =====
  static String get vesselList => dotenv.env['kdn_gis_select_vessel_List'] ?? '';
  static String get vesselRoute => dotenv.env['kdn_gis_select_vessel_Route'] ?? '';

  // ===== 날씨 =====
  static String get weatherInfo => dotenv.env['kdn_wid_select_weather_Info'] ?? '';

  // ===== 항행 정보 =====
  static String get navigationHistory => dotenv.env['kdn_ros_select_navigation_Info'] ?? '';
  static String get navigationVisibility => dotenv.env['kdn_ros_select_visibility_Info'] ?? '';
  static String get navigationWarnings => dotenv.env['kdn_ros_select_navigation_warn_Info'] ?? '';

  // ===== 공공데이터 =====
  static String get holidayInfo => dotenv.env['kdn_load_date'] ?? '';

  // ===== GeoServer =====
  static String get geoserverUrl => dotenv.env['GEOSERVER_URL'] ?? '';

  /// 설정 검증
  static bool get isConfigured {
    return baseUrl.isNotEmpty;
  }

  /// 디버그용 설정 출력 (민감 정보 마스킹)
  static void printConfiguration() {
    AppLogger.d('=== API Configuration ===');
    AppLogger.d('Base URL: ${baseUrl.isNotEmpty ? "SET" : "NOT SET"}');
    AppLogger.d('Login API: ${authLogin.isNotEmpty ? "SET" : "NOT SET"}');
    AppLogger.d('Vessel List API: ${vesselList.isNotEmpty ? "SET" : "NOT SET"}');
    AppLogger.d('Weather API: ${weatherInfo.isNotEmpty ? "SET" : "NOT SET"}');
    AppLogger.d('========================');
  }

  /// 엔드포인트 존재 여부 확인
  static bool hasEndpoint(String key) {
    final value = dotenv.env[key];
    return value != null && value.isNotEmpty;
  }

  /// 모든 필수 엔드포인트 확인
  static bool checkRequiredEndpoints() {
    final required = [
      'kdn_loginForm_key',
      'kdn_usm_select_role_data_key',
      'kdn_gis_select_vessel_List',
      'kdn_wid_select_weather_Info',
    ];

    for (final key in required) {
      if (!hasEndpoint(key)) {
        AppLogger.w('Missing required endpoint: $key');
        return false;
      }
    }
    return true;
  }
}
