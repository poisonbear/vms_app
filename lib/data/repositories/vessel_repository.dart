import 'package:vms_app/data/datasources/vessel_datasource.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart' as domain;
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 선박 및 항로 저장소 구현 (통합)
class VesselRepository implements domain.VesselRepository {
  final VesselDataSource _dataSource;

  VesselRepository(this._dataSource);

  /// 선박 목록 조회
  @override
  Future<List<VesselModel>> getVesselList({String? regDt, int? mmsi}) async {
    try {
      final result = await _dataSource.getVesselList(
        regDt: regDt,
        mmsi: mmsi,
      );

      return result.fold(
        onSuccess: (vessels) => vessels,
        onFailure: (error) {
          AppLogger.e('Vessel Repository Error: $error');
          // 에러 발생 시 빈 리스트 반환 (기존 동작 유지)
          return [];
        },
      );
    } catch (e) {
      AppLogger.e('Vessel Repository Error: $e');
      return [];
    }
  }

  /// 선박 항로 조회 (과거 + 예측)
  @override
  Future<VesselRouteResponse> getVesselRoute({String? regDt, int? mmsi}) async {
    final result = await _dataSource.getVesselRoute(regDt: regDt, mmsi: mmsi);

    return result.fold(
      onSuccess: (route) => route,
      onFailure: (error) {
        AppLogger.e('Route Search Repository Error: $error');
        return VesselRouteResponse(pred: [], past: []);
      },
    );
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef VesselRepositoryImpl = VesselRepository;
typedef RouteSearchRepositoryImpl = VesselRepository;
