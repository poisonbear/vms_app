import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// 자동 포커스 서비스
class AutoFocusService {
  /// MainScreen 진입 시 자동 포커스 실행
  static Future<void> executeAutoFocus({
    required BuildContext context,
    required MapController mapController,
    bool forceUpdate = false,
  }) async {
    try {
      // 사용자 정보 가져오기
      final userState = context.read<UserState>();
      final userMmsi = userState.mmsi;
      
      if (userMmsi == null || userMmsi == 0) {
        AppLogger.w('사용자 MMSI 없음, 기본 위치 유지');
        return;
      }
      
      // 선박 목록 가져오기
      final vesselProvider = context.read<VesselProvider>();
      
      // 선박 목록이 비어있으면 로드
      if (vesselProvider.vessels.isEmpty || forceUpdate) {
        AppLogger.d('선박 목록 로드 중...');
        await vesselProvider.getVesselList();
        
        // 로드 완료 대기
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      // 사용자 선박 찾기
      final userVessel = vesselProvider.vessels.firstWhere(
        (vessel) => vessel.mmsi == userMmsi,
        orElse: () {
          AppLogger.w('사용자 선박을 찾을 수 없음: MMSI $userMmsi');
          // 첫 번째 선박 또는 기본 위치 반환
          if (vesselProvider.vessels.isNotEmpty) {
            return vesselProvider.vessels.first;
          }
          throw Exception('No vessels available');
        },
      );
      
      // 선박 위치로 이동
      final vesselLocation = LatLng(
        userVessel.lttd ?? 35.374509,  // 기본값: 풍력단지
        userVessel.lntd ?? 126.132268,
      );
      
      // 지도 이동 (애니메이션 포함)
      mapController.move(vesselLocation, 13.0);
      
      AppLogger.i('📍 자동 포커스 성공: MMSI $userMmsi at $vesselLocation');
      
    } catch (e) {
      AppLogger.e('자동 포커스 실패: $e');
      
      // 실패 시 기본 위치로
      mapController.move(
        const LatLng(35.374509, 126.132268),  // 풍력단지 중앙
        12.0,
      );
    }
  }
}
