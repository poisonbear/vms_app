import 'dart:convert';
import 'package:latlong2/latlong.dart';

/// GeoJSON 파싱 유틸리티
class GeoUtils {
  /// GeoJSON LineString을 LatLng 리스트로 변환
  static List<LatLng> parseGeoJsonLineString(String geoJsonStr) {
    try {
      final decodedOnce = jsonDecode(geoJsonStr);
      final geoJson =
          decodedOnce is String ? jsonDecode(decodedOnce) : decodedOnce;
      final coords = geoJson['coordinates'] as List;
      return coords.map<LatLng>((c) {
        final lon = double.tryParse(c[0].toString());
        final lat = double.tryParse(c[1].toString());
        if (lat == null || lon == null) throw const FormatException();
        return LatLng(lat, lon);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
