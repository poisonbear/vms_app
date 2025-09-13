import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 위치 포커스 관리 서비스
class LocationFocusService extends ChangeNotifier {
  MapController? _mapController;
  LatLng? _currentLocation;
  double _currentZoom = 13.0;

  // Getter
  MapController? get mapController => _mapController;
  LatLng? get currentLocation => _currentLocation;
  double get currentZoom => _currentZoom;

  /// MapController 설정
  void setMapController(MapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  /// 현재 위치 업데이트
  void updateCurrentLocation(LatLng location) {
    _currentLocation = location;
    notifyListeners();
  }

  /// 현재 위치로 포커스
  void focusCurrentLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.move(_currentLocation!, _currentZoom);
      AppLogger.d('📍 Focused on current location: $_currentLocation');
    }
  }

  /// 특정 위치로 포커스
  void focusOnLocation(LatLng location, {double? zoom}) {
    if (_mapController != null) {
      _mapController!.move(location, zoom ?? _currentZoom);
      AppLogger.d('📍 Focused on location: $location');
    }
  }

  /// 줌 레벨 설정
  void setZoom(double zoom) {
    _currentZoom = zoom;
    if (_mapController != null && _currentLocation != null) {
      _mapController!.move(_currentLocation!, zoom);
    }
    notifyListeners();
  }

  /// 줌 인
  void zoomIn() {
    setZoom(_currentZoom + 1);
  }

  /// 줌 아웃
  void zoomOut() {
    setZoom(_currentZoom - 1);
  }
}
