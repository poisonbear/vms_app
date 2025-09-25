
/// 환경 변수 키 상수 (정리된 버전)
class EnvKeys {
  EnvKeys._();

  // Base
  static const String baseUrl = 'BASE_URL';

  // 인증
  static const String loginUrl = 'kdn_loginForm_key';
  static const String userRoleUrl = 'kdn_usm_select_role_data_key';

  // 회원
  static const String memberInfoUrl = 'kdn_usm_select_member_info_data';
  static const String insertMembershipUrl = 'kdn_usm_insert_membership_key';
  static const String updateMembershipUrl = 'kdn_usm_update_membership_key';
  static const String memberSearchUrl = 'kdn_usm_select_membership_search_key';

  // 약관
  static const String termsUrl = 'kdn_usm_select_cmd_key';

  // 선박
  static const String vesselListUrl = 'kdn_gis_select_vessel_List';
  static const String vesselRouteUrl = 'kdn_gis_select_vessel_Route';

  // 날씨
  static const String weatherInfoUrl = 'kdn_wid_select_weather_Info';

  // 항행
  static const String navigationHistoryUrl = 'kdn_ros_select_navigation_Info';
  static const String navigationVisibilityUrl = 'kdn_ros_select_visibility_Info';
  static const String navigationWarningsUrl = 'kdn_ros_select_navigation_warn_Info';

  // 공공데이터
  static const String holidayInfoUrl = 'kdn_load_date';

  // GeoServer
  static const String geoserverUrl = 'GEOSERVER_URL';

  // Firebase
  static const String firebaseProjectId = 'FIREBASE_PROJECT_ID';
  static const String firebaseApiKey = 'FIREBASE_API_KEY';
}
