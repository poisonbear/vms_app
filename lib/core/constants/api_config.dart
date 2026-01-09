// lib/core/constants/api_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// API 설정 및 엔드포인트 통합 관리
class ApiConfig {
  ApiConfig._();

  // ============================================
  // 환경변수 키 (내부 참조용)
  // ============================================
  static const String _baseUrlKey = 'BASE_URL';
  static const String _geoserverUrlKey = 'GEOSERVER_URL';

  // Auth
  static const String _loginKey = 'kdn_loginForm_key';
  static const String _roleKey = 'kdn_usm_select_role_data_key';
  static const String _registerKey = 'kdn_usm_insert_membership_key';

  // Member
  static const String _memberInfoKey = 'kdn_usm_select_member_info_data';
  static const String _updateMemberKey = 'kdn_usm_update_membership_key';
  static const String _memberSearchKey = 'kdn_usm_select_membership_search_key';
  static const String _findUserIdByMmsiKey = 'kdn_usm_find_user_id_by_mmsi';

  // Terms
  static const String _termsKey = 'kdn_usm_select_cmd_key';

  // Vessel
  static const String _vesselListKey = 'kdn_gis_select_vessel_List';
  static const String _vesselRouteKey = 'kdn_gis_select_vessel_Route';

  // Weather
  static const String _weatherInfoKey = 'kdn_wid_select_weather_Info';

  // Navigation
  static const String _navigationHistoryKey = 'kdn_ros_select_navigation_Info';
  static const String _navigationVisibilityKey =
      'kdn_ros_select_visibility_Info';
  static const String _navigationWarningsKey =
      'kdn_ros_select_navigation_warn_Info';

  // Public Data
  static const String _holidayInfoKey = 'kdn_load_date';

  // ============================================
  // Base URLs
  // ============================================
  static String get baseUrl =>
      _getEnv(_baseUrlKey, 'http://118.40.116.129:8080');
  static String get geoserverUrl => _getEnv(_geoserverUrlKey);

  // ============================================
  // Auth Endpoints
  // ============================================
  static String get authLogin => _getEnv(_loginKey);
  static String get authRole => _getEnv(_roleKey);
  static String get authRegister => _getEnv(_registerKey);

  // ============================================
  // 하위 호환성 별칭 (Deprecated)
  // ============================================
  @Deprecated('Use authLogin instead')
  static String get loginUrl => authLogin;

  @Deprecated('Use authRole instead')
  static String get userRoleUrl => authRole;

  @Deprecated('Use authRegister instead')
  static String get insertMembershipUrl => authRegister;

  @Deprecated('Use memberInfo instead')
  static String get memberInfoUrl => memberInfo;

  @Deprecated('Use updateMember instead')
  static String get updateMembershipUrl => updateMember;

  @Deprecated('Use memberSearch instead')
  static String get memberSearchUrl => memberSearch;

  @Deprecated('Use termsList instead')
  static String get termsUrl => termsList;

  @Deprecated('Use vesselList instead')
  static String get vesselListUrl => vesselList;

  @Deprecated('Use vesselRoute instead')
  static String get vesselRouteUrl => vesselRoute;

  @Deprecated('Use weatherInfo instead')
  static String get weatherInfoUrl => weatherInfo;

  @Deprecated('Use navigationHistory instead')
  static String get navigationHistoryUrl => navigationHistory;

  @Deprecated('Use navigationVisibility instead')
  static String get navigationVisibilityUrl => navigationVisibility;

  @Deprecated('Use navigationWarnings instead')
  static String get navigationWarningsUrl => navigationWarnings;

  @Deprecated('Use holidayInfo instead')
  static String get holidayInfoUrl => holidayInfo;

  // ============================================
  // Member Endpoints
  // ============================================
  static String get memberInfo => _getEnv(_memberInfoKey);
  static String get updateMember => _getEnv(_updateMemberKey);
  static String get memberSearch => _getEnv(_memberSearchKey);
  static String get findUserIdByMmsi => _getEnv(_findUserIdByMmsiKey);

  // ============================================
  // Terms Endpoints
  // ============================================
  static String get termsList => _getEnv(_termsKey);

  // ============================================
  // Vessel Endpoints
  // ============================================
  static String get vesselList => _getEnv(_vesselListKey);
  static String get vesselRoute => _getEnv(_vesselRouteKey);

  // ============================================
  // Weather Endpoints
  // ============================================
  static String get weatherInfo => _getEnv(_weatherInfoKey);

  // ============================================
  // Navigation Endpoints
  // ============================================
  static String get navigationHistory => _getEnv(_navigationHistoryKey);
  static String get navigationVisibility => _getEnv(_navigationVisibilityKey);
  static String get navigationWarnings => _getEnv(_navigationWarningsKey);

  // ============================================
  // Public Data Endpoints
  // ============================================
  static String get holidayInfo => _getEnv(_holidayInfoKey);

  // ============================================
  // Helper Methods
  // ============================================

  /// 환경변수 가져오기 (기본값 지원)
  static String _getEnv(String key, [String defaultValue = '']) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// 전체 URL 생성 (baseUrl + endpoint)
  static String buildUrl(String endpoint) {
    if (endpoint.isEmpty) return '';
    if (endpoint.startsWith('http')) return endpoint;
    return '$baseUrl$endpoint';
  }

  /// 설정 완료 여부 확인
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// 특정 엔드포인트 존재 여부 확인
  static bool hasEndpoint(String key) {
    final value = dotenv.env[key];
    return value != null && value.isNotEmpty;
  }

  /// 필수 엔드포인트 확인
  static bool checkRequiredEndpoints() {
    final required = [
      _loginKey,
      _roleKey,
      _vesselListKey,
      _weatherInfoKey,
    ];

    bool allPresent = true;
    for (final key in required) {
      if (!hasEndpoint(key)) {
        AppLogger.w('Missing required endpoint: $key');
        allPresent = false;
      }
    }
    return allPresent;
  }

  /// 디버그용 설정 출력 (민감 정보 마스킹)
  static void printConfiguration() {
    AppLogger.d('=== API Configuration ===');
    AppLogger.d('Base URL: ${baseUrl.isNotEmpty ? "✓ SET" : "✗ NOT SET"}');
    AppLogger.d(
        'GeoServer: ${geoserverUrl.isNotEmpty ? "✓ SET" : "✗ NOT SET"}');
    AppLogger.d('Login API: ${authLogin.isNotEmpty ? "✓ SET" : "✗ NOT SET"}');
    AppLogger.d(
        'Vessel List: ${vesselList.isNotEmpty ? "✓ SET" : "✗ NOT SET"}');
    AppLogger.d(
        'Weather API: ${weatherInfo.isNotEmpty ? "✓ SET" : "✗ NOT SET"}');
    AppLogger.d('========================');
  }

  /// 모든 설정된 엔드포인트 목록 (디버그용)
  static Map<String, String> getAllEndpoints() {
    return {
      'baseUrl': baseUrl,
      'geoserverUrl': geoserverUrl,
      'authLogin': authLogin,
      'authRole': authRole,
      'authRegister': authRegister,
      'memberInfo': memberInfo,
      'updateMember': updateMember,
      'memberSearch': memberSearch,
      'termsList': termsList,
      'vesselList': vesselList,
      'vesselRoute': vesselRoute,
      'weatherInfo': weatherInfo,
      'navigationHistory': navigationHistory,
      'navigationVisibility': navigationVisibility,
      'navigationWarnings': navigationWarnings,
      'holidayInfo': holidayInfo,
    };
  }
}
