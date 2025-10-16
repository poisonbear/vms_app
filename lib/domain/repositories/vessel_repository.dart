import 'package:vms_app/data/models/vessel_model.dart';

/// 선박 정보 저장소 인터페이스 (항로 검색 기능 포함)
abstract class VesselRepository {
  /// 선박 목록 조회
  Future<List<VesselModel>> getVesselList({String? regDt, int? mmsi});

  /// 선박 항로 조회 (과거 + 예측) - RouteSearchRepository 기능 통합
  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi,
  });
}
