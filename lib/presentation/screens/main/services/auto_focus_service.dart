// lib/presentation/screens/main/services/auto_focus_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';

/// 자동 포커스 결과
class AutoFocusResult {
  final bool success;
  final LatLng? location;
  final int? targetMmsi;
  final String? errorMessage;

  const AutoFocusResult({
    required this.success,
    this.location,
    this.targetMmsi,
    this.errorMessage,
  });

  factory AutoFocusResult.success({
    required LatLng location,
    required int mmsi,
  }) {
    return AutoFocusResult(
      success: true,
      location: location,
      targetMmsi: mmsi,
    );
  }

  factory AutoFocusResult.failure(String error) {
    return AutoFocusResult(
      success: false,
      errorMessage: error,
    );
  }
}

/// MainScreen 자동 포커스 서비스
///
/// - 로그인 시 사용자 선박으로 자동 포커스
/// - 선박 데이터 로드 및 검증
/// - 지도 이동 처리
/// - 에러 핸들링
class AutoFocusService {
  // ============================================
  // Constants
  // ============================================
  static const LatLng _defaultLocation = LatLng(35.374509, 126.132268);
  static const double _defaultZoom = 13.0;
  static const double _fallbackZoom = 12.0;
  static const Duration _vesselLoadDelay = Duration(milliseconds: 800);

  // ============================================
  // Public Methods
  // ============================================

  /// MainScreen 진입 시 자동 포커스 실행
  ///
  /// [context] - BuildContext
  /// [mapController] - 지도 컨트롤러
  /// [forceUpdate] - 선박 데이터 강제 재로드 여부
  /// [zoom] - 줌 레벨 (기본: 13.0)
  static Future<AutoFocusResult> executeAutoFocus({
    required BuildContext context,
    required MapController mapController,
    bool forceUpdate = false,
    double? zoom,
  }) async {
    try {
      AppLogger.d('🎯 ========== Auto Focus Start ==========');

      // 1. 사용자 MMSI 확인
      final userMmsi = _getUserMmsi(context);
      if (userMmsi == null) {
        return _handleNoUserMmsi(mapController);
      }

      // 2. 선박 데이터 로드
      final vessel = await _loadUserVessel(
        context,
        userMmsi,
        forceUpdate,
      );

      if (vessel == null) {
        return _handleVesselNotFound(mapController, userMmsi);
      }

      // 3. 선박 위치로 포커스
      final location = _getVesselLocation(vessel);
      _moveMapToLocation(mapController, location, zoom ?? _defaultZoom);

      AppLogger.i('✅ Auto focus SUCCESS: MMSI $userMmsi at $location');
      AppLogger.d('========================================');

      return AutoFocusResult.success(
        location: location,
        mmsi: userMmsi,
      );
    } catch (e) {
      AppLogger.e('❌ Auto focus FAILED', e);
      AppLogger.d('========================================');

      // 실패 시 기본 위치로 이동
      _moveMapToLocation(mapController, _defaultLocation, _fallbackZoom);

      return AutoFocusResult.failure('Auto focus failed: $e');
    }
  }

  /// 특정 MMSI 선박으로 포커스
  static Future<AutoFocusResult> focusToVessel({
    required BuildContext context,
    required MapController mapController,
    required int mmsi,
    double? zoom,
  }) async {
    try {
      AppLogger.d('🎯 Focusing to vessel: MMSI $mmsi');

      final vesselProvider = context.read<VesselProvider>();

      // 선박 찾기
      final vessel = vesselProvider.vessels.firstWhere(
        (v) => v.mmsi == mmsi,
        orElse: () => throw Exception('Vessel not found: MMSI $mmsi'),
      );

      final location = _getVesselLocation(vessel);
      _moveMapToLocation(mapController, location, zoom ?? _defaultZoom);

      AppLogger.i('✅ Focused to vessel: MMSI $mmsi at $location');

      return AutoFocusResult.success(
        location: location,
        mmsi: mmsi,
      );
    } catch (e) {
      AppLogger.e('Failed to focus to vessel: MMSI $mmsi', e);
      return AutoFocusResult.failure('Focus to vessel failed: $e');
    }
  }

  // ============================================
  // Private Methods
  // ============================================

  /// 사용자 MMSI 가져오기
  static int? _getUserMmsi(BuildContext context) {
    try {
      final userState = context.read<UserState>();
      final mmsi = userState.mmsi;

      if (mmsi == null || mmsi == 0) {
        AppLogger.w('  ⚠️ User MMSI is null or 0');
        return null;
      }

      AppLogger.d('  ✓ User MMSI: $mmsi');
      return mmsi;
    } catch (e) {
      AppLogger.e('  ❌ Failed to get user MMSI', e);
      return null;
    }
  }

  /// 사용자 선박 데이터 로드
  static Future<VesselSearchModel?> _loadUserVessel(
    BuildContext context,
    int userMmsi,
    bool forceUpdate,
  ) async {
    try {
      final vesselProvider = context.read<VesselProvider>();

      // 선박 목록이 비어있거나 강제 업데이트 시 로드
      if (vesselProvider.vessels.isEmpty || forceUpdate) {
        AppLogger.d('  📡 Loading vessel list...');
        await vesselProvider.getVesselList();

        // 로드 완료 대기
        await Future.delayed(_vesselLoadDelay);
        AppLogger.d(
            '  ✓ Vessel list loaded: ${vesselProvider.vessels.length} vessels');
      } else {
        AppLogger.d(
            '  ✓ Using cached vessel list: ${vesselProvider.vessels.length} vessels');
      }

      // 사용자 선박 찾기
      return vesselProvider.vessels.firstWhere(
        (vessel) => vessel.mmsi == userMmsi,
        orElse: () {
          AppLogger.w('  ⚠️ User vessel not found: MMSI $userMmsi');

          // 첫 번째 선박 반환 (fallback)
          if (vesselProvider.vessels.isNotEmpty) {
            final fallback = vesselProvider.vessels.first;
            AppLogger.w(
                '  → Using first vessel as fallback: MMSI ${fallback.mmsi}');
            return fallback;
          }

          throw Exception('No vessels available');
        },
      );
    } catch (e) {
      AppLogger.e('  ❌ Failed to load user vessel', e);
      return null;
    }
  }

  /// 선박 위치 가져오기
  static LatLng _getVesselLocation(VesselSearchModel vessel) {
    final lat = vessel.lttd ?? _defaultLocation.latitude;
    final lng = vessel.lntd ?? _defaultLocation.longitude;
    return LatLng(lat, lng);
  }

  /// 지도 이동
  static void _moveMapToLocation(
    MapController mapController,
    LatLng location,
    double zoom,
  ) {
    try {
      mapController.move(location, zoom);
      AppLogger.d('  ✓ Map moved to: $location (zoom: $zoom)');
    } catch (e) {
      AppLogger.e('  ❌ Failed to move map', e);
    }
  }

  /// 사용자 MMSI 없음 처리
  static AutoFocusResult _handleNoUserMmsi(MapController mapController) {
    AppLogger.w('  → Keeping default location');
    AppLogger.d('========================================');

    return AutoFocusResult.failure('User MMSI not available');
  }

  /// 선박 찾기 실패 처리
  static AutoFocusResult _handleVesselNotFound(
    MapController mapController,
    int userMmsi,
  ) {
    AppLogger.w('  → Moving to default location');
    _moveMapToLocation(mapController, _defaultLocation, _fallbackZoom);
    AppLogger.d('========================================');

    return AutoFocusResult.failure('Vessel not found: MMSI $userMmsi');
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// 선박 위치 유효성 체크
  static bool isValidVesselLocation(VesselSearchModel vessel) {
    return vessel.lttd != null && vessel.lntd != null;
  }

  /// 기본 위치 가져오기
  static LatLng getDefaultLocation() => _defaultLocation;

  /// 기본 줌 레벨 가져오기
  static double getDefaultZoom() => _defaultZoom;
}
