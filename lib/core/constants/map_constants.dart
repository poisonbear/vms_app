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
}
