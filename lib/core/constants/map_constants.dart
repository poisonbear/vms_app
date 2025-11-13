/// 지도 관련 상수
class MapConstants {
  MapConstants._();

  // ============ Zoom Levels ============
  static const double zoomMin = 5.0;
  static const double zoomDefault = 13.0;
  static const double zoomMax = 18.0;
  static const double zoomCity = 10.0;
  static const double zoomStreet = 15.0;
  static const double zoomDetail = 17.0;

  // ============ Map Boundaries (대한민국) ============
  static const double latitudeMin = 33.0;
  static const double latitudeMax = 38.9;
  static const double longitudeMin = 124.5;
  static const double longitudeMax = 132.0;

  // ============ Default Locations ============
  static const double defaultLatitude = 36.5; // 대한민국 중심
  static const double defaultLongitude = 127.5;

  // ============ Update Intervals ============
  static const int vesselUpdateSeconds = 2;
  static const int locationUpdateSeconds = 5;

  // ============ Marker Sizes ============
  static const double markerSizeSmall = 20.0;
  static const double markerSizeMedium = 30.0;
  static const double markerSizeLarge = 40.0;

  // ============ 항행경보 구역 타입 ============
  static const String warningShapeCircle = 'circle';
  static const String warningShapePolygon = 'polygon';

  // ============ 항행경보 색상 ============
  static const int warningColorRed = 0xFFFF0000; // 접근금지 - 빨강
  static const int warningColorOrange = 0xFFFF8C00; // 항행정보 - 주황
  static const int warningColorYellow = 0xFFFFD700; // 기타 - 노랑

  // ============ 항행경보 투명도 ============
  static const double warningFillOpacity = 0.3;
  static const double warningBorderOpacity = 0.8;

  // ============ 항행경보 선 두께 ============
  static const double warningBorderWidth = 2.0;

  // ============ NM(해리)을 위도/경도로 변환 ============
  /// 1 NM = 1.852 km = 약 0.0166667도 (위도 기준)
  static const double nmToDegreesLat = 0.0166667;

  // ============ 경보 분류 키워드 ============
  static const String alarmTypeProhibited = '접근금지';
  static const String alarmTypeInfo = '항행정보';

  // ============ 라벨 폰트 크기 ============
  static const double warningLabelFontSize = 11.0;
  static const double warningLabelFontSizeSmall = 9.0;

  // ============ 라벨 배경 색상 ============
  static const int warningLabelBackgroundColor = 0x00000000; // 완전 투명

  // ============ 라벨 텍스트 색상 ============
  static const int warningLabelTextColor = 0xFFFFFFFF; // 흰색

  // ============ 라벨 패딩 ============
  static const double warningLabelPaddingHorizontal = 8.0;
  static const double warningLabelPaddingVertical = 4.0;

  // ============ 라벨 둥근 모서리 ============
  static const double warningLabelBorderRadius = 4.0;
}
