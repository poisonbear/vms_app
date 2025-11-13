import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/screens/main/utils/vessel_focus_helper.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// MainScreen 초기화 확장
extension MainScreenInit on State {
  /// 자동 포커스 처리
  Future<void> handleAutoFocus({
    required bool autoFocusLocation,
    required dynamic mapController,
  }) async {
    if (!autoFocusLocation) return;

    try {
      // 약간의 지연을 주어 화면이 완전히 로드되도록 함
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      if (!context.mounted) return;

      // 사용자 MMSI 가져오기
      final userMmsi = context.read<UserState>().mmsi;
      if (userMmsi == null || userMmsi == 0) {
        AppLogger.w('사용자 MMSI가 없어 자동 포커스를 건너뜁니다');
        return;
      }

      // 선박 목록 가져오기
      final vesselProvider = context.read<VesselProvider>();

      // 선박 목록이 없으면 먼저 로드
      if (vesselProvider.vessels.isEmpty) {
        await vesselProvider.getVesselList();

        // 로드 완료 대기
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;
      if (!context.mounted) return;

      // 선박 위치로 포커스
      VesselFocusHelper.focusOnUserVessel(
        mapController: mapController,
        vessels: vesselProvider.vessels,
        userMmsi: userMmsi,
        zoom: 13.0, // 로그인 시 좀 더 가까이 포커스
      );

      AppLogger.i('로그인 후 자동 포커스 완료 (MMSI: $userMmsi)');
    } catch (e) {
      AppLogger.e('자동 포커스 실패: $e');
    }
  }
}
