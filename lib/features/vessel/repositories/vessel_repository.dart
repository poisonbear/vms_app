import '../datasources/vessel_datasource.dart';
import '../models/vessel_model.dart';
import '../models/vessel_route_model.dart';

/// 선박 관련 데이터 저장소
class VesselRepository {
  const VesselRepository({
    required VesselDatasource datasource,
  }) : _datasource = datasource;

  final VesselDatasource _datasource;

  /// 선박 목록 조회
  Future<List<VesselModel>> getVesselList({
    String? regDt,
    int? mmsi,
  }) {
    return _datasource.getVesselList(regDt: regDt, mmsi: mmsi);
  }

  /// 선박 항로 조회
  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi,
  }) {
    return _datasource.getVesselRoute(regDt: regDt, mmsi: mmsi);
  }
}