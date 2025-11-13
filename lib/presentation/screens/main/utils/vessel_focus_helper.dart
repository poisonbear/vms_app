import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/vessel_model.dart';

/// 선박 위치 포커스 헬퍼
class VesselFocusHelper {
  /// 사용자 MMSI 선박으로 포커스
  static void focusOnUserVessel({
    required MapController mapController,
    required List<VesselSearchModel> vessels,
    required int userMmsi,
    double zoom = 12.0,
  }) {
    try {
      // 사용자 MMSI와 일치하는 선박 찾기
      final userVessel = vessels.firstWhere(
        (vessel) => vessel.mmsi == userMmsi,
        orElse: () => vessels.isNotEmpty
            ? vessels.first
            : throw Exception('No vessels found'),
      );

      // 선박 위치로 이동
      final vesselLocation = LatLng(
        userVessel.lttd ?? 35.3790988,
        userVessel.lntd ?? 126.3854693,
      );

      mapController.move(vesselLocation, zoom);

      AppLogger.i(' 사용자 선박(MMSI: $userMmsi) 위치로 포커스: $vesselLocation');
    } catch (e) {
      AppLogger.e('선박 포커스 실패: $e');

      // 실패 시 기본 위치(풍력단지)로 이동
      mapController.move(
        const LatLng(35.374509, 126.132268),
        12.0,
      );
    }
  }

  /// 특정 선박으로 포커스
  static void focusOnVessel({
    required MapController mapController,
    required VesselSearchModel vessel,
    double zoom = 13.0,
  }) {
    final vesselLocation = LatLng(
      vessel.lttd ?? 35.3790988,
      vessel.lntd ?? 126.3854693,
    );

    mapController.move(vesselLocation, zoom);

    AppLogger.d(' 선박(MMSI: ${vessel.mmsi}) 위치로 포커스: $vesselLocation');
  }
}
