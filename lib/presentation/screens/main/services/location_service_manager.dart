// lib/presentation/screens/main/services/location_service_manager.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import '../utils/location_utils.dart';

/// 위치 권한 상태
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// 위치 서비스 결과
class LocationResult {
  final LatLng? location;
  final LocationPermissionStatus status;
  final String? errorMessage;

  const LocationResult({
    this.location,
    required this.status,
    this.errorMessage,
  });

  bool get isSuccess => location != null;
  bool get hasError => errorMessage != null;

  factory LocationResult.success(LatLng location) {
    return LocationResult(
      location: location,
      status: LocationPermissionStatus.granted,
    );
  }

  factory LocationResult.failure({
    required LocationPermissionStatus status,
    String? errorMessage,
  }) {
    return LocationResult(
      status: status,
      errorMessage: errorMessage,
    );
  }
}

/// MainScreen 전용 위치 서비스 관리자
///
/// - 위치 권한 체크 및 요청
/// - 현재 위치 가져오기
/// - 자동 위치 포커스
/// - UI 피드백 처리
class LocationServiceManager {
  // ============================================
  // Constants
  // ============================================
  //static const LatLng _defaultLocation = LatLng(35.374509, 126.132268);
  static const String _autoFocusKey = 'first_auto_focus';
  static const Duration _locationTimeout = Duration(seconds: 10);

  // ============================================
  // Dependencies
  // ============================================
  final MainLocationService _locationService = MainLocationService();

  // ============================================
  // Public Methods
  // ============================================

  /// 현재 위치 가져오기
  ///
  /// 권한이 없거나 위치를 가져올 수 없으면 null 반환
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final location = LatLng(position.latitude, position.longitude);
        AppLogger.d('Current location: $location');
        return location;
      }
      return null;
    } catch (e) {
      AppLogger.e('Failed to get current location', e);
      return null;
    }
  }

  /// 자동 위치 포커스
  ///
  /// - 첫 실행 체크
  /// - 권한 요청
  /// - 현재 위치로 이동
  /// - UI 피드백
  Future<LocationResult> autoFocusToMyLocation(
    BuildContext context, {
    bool forceAutoFocus = false,
  }) async {
    try {
      AppLogger.d('자동 위치 포커스 시작...');

      // 첫 실행 체크
      if (!forceAutoFocus) {
        final shouldSkip = await _shouldSkipAutoFocus();
        if (shouldSkip) {
          AppLogger.d('첫 실행이 아니므로 자동 포커스 건너뜀');
          return LocationResult.failure(
            status: LocationPermissionStatus.granted,
            errorMessage: 'Auto focus skipped',
          );
        }
      }

      // 권한 체크
      final permissionStatus = await _checkLocationPermission();

      //mounted 체크 추가 (라인 118-122 근처)
      if (!context.mounted) {
        AppLogger.w('Context is not mounted after permission check');
        return LocationResult.failure(
          status: permissionStatus,
          errorMessage: 'Context not mounted',
        );
      }

      if (permissionStatus != LocationPermissionStatus.granted) {
        return _handlePermissionFailure(context, permissionStatus);
      }

      // 위치 서비스 활성화 체크
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      //mounted 체크 추가 (라인 125-129 근처)
      if (!context.mounted) {
        AppLogger.w('Context is not mounted after service check');
        return LocationResult.failure(
          status: LocationPermissionStatus.serviceDisabled,
          errorMessage: 'Context not mounted',
        );
      }

      if (!serviceEnabled) {
        return _handleServiceDisabled(context);
      }

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      );

      final location = LatLng(position.latitude, position.longitude);
      AppLogger.i('위치 포커스 성공: $location');

      // 첫 실행 플래그 저장
      await _markAutoFocusCompleted();

      //mounted 체크 유지 (라인 141 근처 - 기존에 있던 체크)
      // 성공 피드백
      if (context.mounted) {
        showTopSnackBar(context, '현재 위치로 이동했습니다.');
      }

      return LocationResult.success(location);
    } catch (e) {
      AppLogger.e('자동 위치 포커스 오류', e);

      //mounted 체크 유지 (라인 149 근처 - 기존에 있던 체크)
      if (context.mounted) {
        showTopSnackBar(context, ErrorMessages.locationGetFailed);
      }

      return LocationResult.failure(
        status: LocationPermissionStatus.denied,
        errorMessage: e.toString(),
      );
    }
  }

  /// 위치 권한 체크 및 요청
  Future<bool> checkAndRequestLocationPermission() async {
    final status = await _checkLocationPermission();

    if (status == LocationPermissionStatus.granted) {
      AppLogger.d('위치 권한이 이미 허용되어 있습니다.');
      return true;
    }

    if (status == LocationPermissionStatus.deniedForever) {
      AppLogger.w('위치 권한이 영구 거부되었습니다.');
      return false;
    }

    // 권한 요청
    final permission = await Geolocator.requestPermission();
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (granted) {
      AppLogger.i('위치 권한 허용됨');
    } else {
      AppLogger.w('위치 권한 거부됨');
    }

    return granted;
  }

  // ============================================
  // Private Methods
  // ============================================

  /// 위치 권한 상태 확인
  Future<LocationPermissionStatus> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      AppLogger.d('위치 권한 허용됨');
      return LocationPermissionStatus.granted;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.d('위치 권한 거부됨');
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.d('위치 권한 영구 거부됨');
      return LocationPermissionStatus.deniedForever;
    }

    return permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always
        ? LocationPermissionStatus.granted
        : LocationPermissionStatus.denied;
  }

  /// 자동 포커스 건너뛰기 체크
  Future<bool> _shouldSkipAutoFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstAutoFocus = prefs.getBool(_autoFocusKey) ?? true;
    return !isFirstAutoFocus;
  }

  /// 자동 포커스 완료 표시
  Future<void> _markAutoFocusCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoFocusKey, false);
  }

  /// 권한 실패 처리
  LocationResult _handlePermissionFailure(
    BuildContext context,
    LocationPermissionStatus status,
  ) {
    String message;

    if (status == LocationPermissionStatus.deniedForever) {
      message = ErrorMessages.locationPermissionSettings;
      AppLogger.w('위치 권한이 영구 거부됨');
    } else {
      message = ErrorMessages.locationPermissionRequired;
      AppLogger.d('위치 권한 거부됨');
    }

    //기존 mounted 체크 유지
    if (context.mounted) {
      showTopSnackBar(context, message);
    }

    return LocationResult.failure(
      status: status,
      errorMessage: message,
    );
  }

  /// 위치 서비스 비활성화 처리
  LocationResult _handleServiceDisabled(BuildContext context) {
    const message = ErrorMessages.locationServiceActivationRequired;
    AppLogger.w('위치 서비스가 비활성화됨');

    //기존 mounted 체크 유지
    if (context.mounted) {
      showTopSnackBar(context, message);
    }

    return LocationResult.failure(
      status: LocationPermissionStatus.serviceDisabled,
      errorMessage: message,
    );
  }

  // ============================================
  // Cleanup
  // ============================================

  /// 리소스 정리
  void dispose() {
    // 필요시 리소스 정리
    AppLogger.d('LocationServiceManager disposed');
  }
}
