// lib/presentation/services/ui/ui_services.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

// ============================================
// PopupService - 팝업 상태 관리
// ============================================

/// 팝업 서비스
///
/// 앱 전체의 팝업 상태를 관리하고 중복 팝업을 방지합니다.
class PopupService {
  static final Map<String, bool> _activePopups = {};
  static final Map<String, Completer> _popupCompleters = {};

  // 팝업 타입 상수
  static const String TURBINE_ENTRY_ALERT = 'turbine_entry_alert';
  static const String WEATHER_ALERT = 'weather_alert';
  static const String SUBMARINE_CABLE_ALERT = 'submarine_cable_alert';
  static const String emergencyPopup = 'emergency';
  static const String warningPopup = 'warning';
  static const String infoPopup = 'info';
  static const String confirmPopup = 'confirm';

  /// 팝업 활성 상태 확인
  bool isPopupActive(String type) {
    return _activePopups[type] ?? false;
  }

  /// 팝업 표시
  void showPopup(String type) {
    _activePopups[type] = true;
    AppLogger.d('Popup shown: $type');
  }

  /// 팝업 숨김
  void hidePopup(String type) {
    _activePopups[type] = false;
    _popupCompleters[type]?.complete();
    _popupCompleters.remove(type);
    AppLogger.d('Popup hidden: $type');
  }

  /// 팝업 닫힐 때까지 대기
  Future<void> waitForPopupClose(String type) {
    if (!isPopupActive(type)) {
      return Future.value();
    }

    _popupCompleters[type] = Completer();
    return _popupCompleters[type]!.future;
  }

  /// 모든 팝업 닫기
  void closeAllPopups(BuildContext context) {
    int popCount = 0;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == '/') {
        return true;
      }
      popCount++;
      return false;
    });

    _activePopups.clear();
    AppLogger.d('Closed $popCount popups');
  }

  /// 초기화
  void reset() {
    _activePopups.clear();
    _popupCompleters.clear();
  }

  /// 리소스 정리
  void dispose() {
    reset();
  }
}

// ============================================
// LocationFocusService - 위치 포커스 (UI)
// ============================================

/// 위치 포커스 서비스
///
/// MapController와 연동하여 지도 위치 이동 및 포커스를 관리합니다.
class LocationFocusService {
  MapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _focusedLocation;
  final bool _isTracking = false;
  final bool _isAutoFocusEnabled = false;
  StreamSubscription<Position>? _positionSubscription;
  Function(LatLng)? _onLocationUpdate;
  Function(String)? _onError;

  // 기본 위치 및 줌 레벨
  static const LatLng defaultLocation = LatLng(35.374509, 126.132268);
  static const double defaultZoom = 13.0;
  static const double detailZoom = 16.0;
  static const double overviewZoom = 10.0;

  /// MapController 설정
  void setMapController(MapController controller) {
    _mapController = controller;
  }

  /// Getters
  LatLng? get currentLocation => _currentLocation;
  LatLng? get focusedLocation => _focusedLocation;
  bool get isTracking => _isTracking;
  bool get isAutoFocusEnabled => _isAutoFocusEnabled;

  /// 현재 위치로 포커스
  Future<bool> focusToCurrentLocation({
    double? zoom,
    bool animate = true,
  }) async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _onError?.call('위치 권한이 필요합니다');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _focusedLocation = _currentLocation;

      if (_mapController != null && _currentLocation != null) {
        moveToLocation(_currentLocation!, zoom: zoom);
      }

      _onLocationUpdate?.call(_currentLocation!);
      AppLogger.d('Focused to current location: $_currentLocation');
      return true;
    } catch (e) {
      AppLogger.e('Failed to focus to current location: $e');
      _onError?.call('현재 위치를 가져올 수 없습니다');
      return false;
    }
  }

  /// 특정 위치로 이동
  void moveToLocation(LatLng location, {double? zoom}) {
    _mapController?.move(location, zoom ?? defaultZoom);
  }

  /// 위치 권한 체크
  Future<bool> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return requested != LocationPermission.denied &&
          requested != LocationPermission.deniedForever;
    }
    return permission != LocationPermission.deniedForever;
  }

  /// 리소스 정리
  void dispose() {
    _positionSubscription?.cancel();
  }
}
