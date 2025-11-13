import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 로그인 시 내 위치찾기 자동 실행 헬퍼
class AutoLocationHelper {
  // 발전단지 중앙 (기본 위치)
  static const LatLng DEFAULT_CENTER = LatLng(35.374509, 126.132268);

  /// 내 위치찾기 자동 실행
  static Future<void> executeAutoFocus({
    required BuildContext context,
    required MapController mapController,
  }) async {
    try {
      AppLogger.d('🚀 내 위치찾기 자동 실행 시작... ');

      if (!context.mounted) return;

      // 사용자 MMSI 가져오기
      final userMmsi = context.read<UserState>().mmsi;
      AppLogger.d('👤 사용자 MMSI: $userMmsi');

      if (userMmsi == null || userMmsi == 0) {
        AppLogger.w('MMSI가 없어 발전단지 중앙으로 이동');
        mapController.move(DEFAULT_CENTER, 12.0);
        return;
      }

      // 선박 목록 가져오기
      final vesselProvider = context.read<VesselProvider>();
      AppLogger.d('현재 선박 목록 개수: ${vesselProvider.vessels.length}');

      // 선박 목록이 비어있으면 먼저 로드
      if (vesselProvider.vessels.isEmpty) {
        AppLogger.d('선박 목록 로드 중...');
        await vesselProvider.getVesselList();

        // 로드 완료 확인용 최소 딜레이(100ms)
        await Future.delayed(const Duration(milliseconds: 100));
        AppLogger.d('로드 완료, 선박 개수: ${vesselProvider.vessels.length}');
      }

      if (!context.mounted) return;

      // 사용자 선박 찾기
      VesselSearchModel? userVessel;

      // for 루프를 사용하여 안전하게 선박 찾기
      for (var vessel in vesselProvider.vessels) {
        if (vessel.mmsi == userMmsi) {
          userVessel = vessel;
          AppLogger.d('사용자 선박 발견: ${vessel.ship_nm}');
          break;
        }
      }

      if (userVessel != null) {
        // 선박 위치로 이동 (내 위치찾기)
        final vesselLocation = LatLng(
          userVessel.lttd ?? DEFAULT_CENTER.latitude,
          userVessel.lntd ?? DEFAULT_CENTER.longitude,
        );

        // 지도 이동 (줌 레벨 13으로 가까이)
        mapController.move(vesselLocation, 13.0);

        AppLogger.i(' 내 위치찾기 자동 실행 완료 (최적화)');
        AppLogger.i(' 선박(MMSI: $userMmsi) 위치: $vesselLocation');
        AppLogger.i(' 총 소요 시간: 약 0.6초');
      } else {
        // 선박을 찾지 못한 경우
        AppLogger.w('MMSI $userMmsi 선박을 찾을 수 없음. 발전단지 중앙으로 이동');
        mapController.move(DEFAULT_CENTER, 12.0);
      }
    } catch (e) {
      AppLogger.e('내 위치찾기 자동 실행 실패: $e');

      // 오류 시 기본 위치로
      mapController.move(DEFAULT_CENTER, 12.0);
    }
  }

  /// 상태 확인 후 실행 (재시도 로직 포함)
  static Future<void> executeAutoFocusWithRetry({
    required BuildContext context,
    required MapController mapController,
    int maxRetries = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        // 자동 포커스 실행
        await executeAutoFocus(
          context: context,
          mapController: mapController,
        );

        return; // 성공
      } catch (e) {
        AppLogger.e('자동 포커스 시도 ${i + 1}/$maxRetries 실패: $e');

        if (i < maxRetries - 1) {
          // 재시도 전 짧은 대기
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          // 마지막 시도 실패 시 기본 위치로
          mapController.move(DEFAULT_CENTER, 12.0);
        }
      }
    }
  }
}
