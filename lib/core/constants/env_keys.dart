/// 환경 변수 키 상수
class EnvKeys {
  EnvKeys._();

  // API URLs
  static const String loginUrl = 'kdn_loginForm_key';
  static const String userRoleUrl = 'kdn_usm_select_role_data_key';
  static const String termsUrl = 'kdn_usm_select_cmd_key';
  static const String vesselListUrl = 'kdn_gis_select_vessel_List';
  static const String weatherInfoUrl = 'kdn_wid_select_weather_Info';
  static const String memberInfoUrl = 'kdn_usm_select_member_info_data';
  static const String updateMembershipUrl = 'kdn_usm_update_membership_key';
  
  // Firebase
  static const String firebaseApiKey = 'firebase_api_key';
  static const String firebaseProjectId = 'firebase_project_id';
  
  // Other
  static const String mapboxToken = 'mapbox_access_token';
}
