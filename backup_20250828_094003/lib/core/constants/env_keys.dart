/// 환경 변수 키 상수
class EnvKeys {
  EnvKeys._();

  // API 관련
  static const String baseUrl = 'BASE_URL';
  static const String apiKey = 'API_KEY';
  static const String apiVersion = 'API_VERSION';

  // 약관 API
  static const String cmdSelectTerms = 'CMD_SELECT_TERMS';
  static const String cmdGetTerms = 'CMD_GET_TERMS';

  // 항행 API
  static const String rosSelectNavigation = 'kdn_ros_select_navigation_Info';
  static const String rosSelectVisibility = 'kdn_ros_select_visibility_Info';
  static const String rosSelectWarnings = 'kdn_ros_select_navigation_warn_Info';

  // 선박 API
  static const String gisSelectVessel = 'kdn_gis_select_vessel_Info';
  static const String gisSelectRoute = 'kdn_gis_select_vessel_Route';

  // 지도 관련
  static const String mapApiKey = 'MAP_API_KEY';
  static const String mapTileUrl = 'MAP_TILE_URL';
}
