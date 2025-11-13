// lib/core/services/location/location_manager.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'location_service.dart';

/// 위치 관리자
///
/// LocationService를 사용하여 비즈니스 로직을 처리합니다.
/// 자동 포커스, 권한 관리 등을 담당합니다.
class LocationManager {
  final LocationService _locationService = LocationService();

  /// 현재 위치 가져오기
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.e('Failed to get current location: $e');
      return null;
    }
  }

  /// 자동 위치 포커스
  ///
  /// 첫 실행 또는 명시적 요청 시 현재 위치로 이동합니다.
  Future<LatLng?> autoFocusToMyLocation(
    BuildContext context, {
    bool autoFocusLocation = false,
  }) async {
    try {
      AppLogger.d('자동 위치 포커스 시작...');

      final prefs = await SharedPreferences.getInstance();
      final isFirstAutoFocus = prefs.getBool('first_auto_focus') ?? true;

      if (!isFirstAutoFocus && !autoFocusLocation) {
        return null;
      }

      // 권한 체크
      final hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) {
        AppLogger.d('위치 권한 없음');
        return null;
      }

      // 위치 서비스 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('위치 서비스가 비활성화됨');
        if (context.mounted) {
          _showSnackBar(context, '위치 서비스를 활성화해주세요.');
        }
        return null;
      }

      AppLogger.d('현재 위치 가져오는 중...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.d(
          '위치 획득 - 위도: ${position.latitude}, 경도: ${position.longitude}');

      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      await prefs.setBool('first_auto_focus', false);

      if (context.mounted) {
        _showSnackBar(context, '현재 위치로 이동했습니다.');
      }

      return currentLocation;
    } catch (e) {
      AppLogger.e('자동 위치 포커스 오류: $e');
      return const LatLng(35.374509, 126.132268); // 기본 위치
    }
  }

  /// 위치 권한 체크 및 요청
  Future<bool> checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      AppLogger.d('이미 위치 권한이 허용되어 있습니다.');
      return true;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.d('위치 권한 거부됨');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.d('위치 권한이 영구 거부됨');
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// 위치 추적 시작
  Future<void> startLocationTracking() async {
    await _locationService.startLocationTracking();
  }

  /// 위치 추적 중지
  void stopLocationTracking() {
    _locationService.stopLocationTracking();
  }

  /// 위치 스트림
  Stream<Position> get positionStream => _locationService.positionStream;

  /// 현재 위치 (캐시됨)
  Position? get currentPosition => _locationService.currentPosition;

  /// 거리 계산 (미터)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _locationService.calculateDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 방위각 계산
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _locationService.calculateBearing(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 리소스 정리
  void dispose() {
    _locationService.dispose();
  }

  // ============================================
  // Private 헬퍼
  // ============================================

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
