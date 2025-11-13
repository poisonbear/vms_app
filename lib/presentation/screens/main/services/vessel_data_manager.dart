// lib/presentation/screens/main/services/vessel_data_manager.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';

/// 선박 데이터 로드 결과
class VesselLoadResult {
  final bool success;
  final int vesselCount;
  final String? errorMessage;
  final DateTime loadedAt;

  const VesselLoadResult({
    required this.success,
    required this.vesselCount,
    this.errorMessage,
    required this.loadedAt,
  });

  factory VesselLoadResult.success(int count) {
    return VesselLoadResult(
      success: true,
      vesselCount: count,
      loadedAt: DateTime.now(),
    );
  }

  factory VesselLoadResult.failure(String error) {
    return VesselLoadResult(
      success: false,
      vesselCount: 0,
      errorMessage: error,
      loadedAt: DateTime.now(),
    );
  }
}

/// MainScreen 전용 선박 데이터 관리자
///
/// - 선박 데이터 로드
/// - 역할별 필터링
/// - Provider 상태 관리
/// - 에러 핸들링
class VesselDataManager {
  // ============================================
  // Constants
  // ============================================
  static const int _adminMmsi = 0;

  // ============================================
  // Internal State
  // ============================================
  VesselLoadResult? _lastLoadResult;
  bool _isLoading = false;

  // ============================================
  // Getters
  // ============================================
  VesselLoadResult? get lastLoadResult => _lastLoadResult;
  bool get isLoading => _isLoading;

  // ============================================
  // Public Methods
  // ============================================

  /// 선박 데이터 로드 및 맵 업데이트
  ///
  /// 사용자 역할에 따라 다른 MMSI로 데이터 로드
  /// - ROLE_USER: 사용자 MMSI
  /// - 기타: 전체 선박 (MMSI=0)
  ///
  /// [forceRefresh] - true 시 캐시를 무시하고 서버에서 새로 가져옴
  Future<VesselLoadResult> loadVesselDataAndUpdateMap(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    if (!context.mounted) {
      return VesselLoadResult.failure('Context not mounted');
    }

    if (_isLoading) {
      AppLogger.w('Vessel data load already in progress');
      return _lastLoadResult ?? VesselLoadResult.failure('Load in progress');
    }

    _isLoading = true;

    try {
      // 사용자 정보 가져오기
      final userState = context.read<UserState>();
      final mmsi = userState.mmsi ?? _adminMmsi;
      final role = userState.role;

      AppLogger.d('Loading vessel data...');
      AppLogger.d('- Role: $role');
      AppLogger.d('- MMSI: $mmsi');
      AppLogger.d('- Force Refresh: $forceRefresh');

      // MMSI 결정
      final targetMmsi = _determineTargetMmsi(role, mmsi);

      // 선박 데이터 로드 (forceRefresh 전달)
      final vesselProvider = context.read<VesselProvider>();
      await vesselProvider.getVesselList(
        mmsi: targetMmsi,
        forceRefresh: forceRefresh,
      );

      // 결과 저장
      final vesselCount = vesselProvider.vessels.length;
      _lastLoadResult = VesselLoadResult.success(vesselCount);

      // 캐시 통계 로깅
      final cacheStats = vesselProvider.getCacheStatistics();
      AppLogger.i('Vessel data loaded: $vesselCount vessels');
      AppLogger.d('Cache Stats: $cacheStats');

      return _lastLoadResult!;
    } catch (e) {
      final errorMessage = 'Failed to load vessel data: $e';
      AppLogger.e(errorMessage);

      _lastLoadResult = VesselLoadResult.failure(errorMessage);
      return _lastLoadResult!;
    } finally {
      _isLoading = false;
    }
  }

  /// 선박 데이터 강제 새로고침
  ///
  /// 캐시를 클리어하고 서버에서 최신 데이터를 가져옵니다.
  Future<VesselLoadResult> refreshVesselData(BuildContext context) async {
    if (!context.mounted) {
      return VesselLoadResult.failure('Context not mounted');
    }

    try {
      AppLogger.d('Refreshing vessel data...');

      // 캐시 클리어
      final vesselProvider = context.read<VesselProvider>();
      vesselProvider.clearCache();

      AppLogger.d('  ✓ Cache cleared');

      // 서버에서 새로 로드 (forceRefresh=true)
      return await loadVesselDataAndUpdateMap(context, forceRefresh: true);
    } catch (e) {
      final errorMessage = 'Failed to refresh vessel data: $e';
      AppLogger.e(errorMessage);
      return VesselLoadResult.failure(errorMessage);
    }
  }

  /// 특정 MMSI 선박 데이터만 로드
  Future<VesselLoadResult> loadSpecificVessel(
    BuildContext context,
    int mmsi,
  ) async {
    if (!context.mounted) {
      return VesselLoadResult.failure('Context not mounted');
    }

    if (mmsi <= 0) {
      return VesselLoadResult.failure('Invalid MMSI: $mmsi');
    }

    try {
      AppLogger.d('Loading specific vessel: MMSI $mmsi');

      final vesselProvider = context.read<VesselProvider>();
      await vesselProvider.getVesselList(mmsi: mmsi);

      final vesselCount = vesselProvider.vessels.length;
      final result = VesselLoadResult.success(vesselCount);

      AppLogger.i('Specific vessel loaded: $vesselCount vessels');

      return result;
    } catch (e) {
      final errorMessage = 'Failed to load specific vessel: $e';
      AppLogger.e(errorMessage);
      return VesselLoadResult.failure(errorMessage);
    }
  }

  // ============================================
  // Private Methods
  // ============================================

  /// 역할에 따른 대상 MMSI 결정
  int _determineTargetMmsi(String? role, int userMmsi) {
    if (role == null) {
      AppLogger.w('User role is null, using admin MMSI');
      return _adminMmsi;
    }

    // ROLE_USER는 사용자 MMSI 사용
    if (role == 'ROLE_USER') {
      if (userMmsi <= 0) {
        AppLogger.w('ROLE_USER but invalid MMSI, using admin MMSI');
        return _adminMmsi;
      }
      return userMmsi;
    }

    // 관리자 및 발전단지 운영자는 전체 선박 조회
    // ROLE_ADMIN, ROLE_OPER 등 기타 역할은 전체 선박 조회
    return _adminMmsi;
  }

  // ============================================
  // Statistics
  // ============================================

  /// 로드 통계 가져오기
  Map<String, dynamic> getLoadStatistics() {
    if (_lastLoadResult == null) {
      return {
        'status': 'never_loaded',
        'isLoading': _isLoading,
      };
    }

    return {
      'status': _lastLoadResult!.success ? 'success' : 'failure',
      'vesselCount': _lastLoadResult!.vesselCount,
      'loadedAt': _lastLoadResult!.loadedAt.toIso8601String(),
      'errorMessage': _lastLoadResult!.errorMessage,
      'isLoading': _isLoading,
    };
  }

  // ============================================
  // Cleanup
  // ============================================

  /// 상태 초기화
  void reset() {
    _lastLoadResult = null;
    _isLoading = false;
    AppLogger.d('VesselDataManager reset');
  }

  /// 리소스 정리
  void dispose() {
    reset();
    AppLogger.d('VesselDataManager disposed');
  }
}
