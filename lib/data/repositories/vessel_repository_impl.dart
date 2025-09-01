import 'package:vms_app/data/datasources/remote/vessel_remote_datasource.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/core/utils/logger.dart';

class VesselRepositoryImpl implements VesselRepository {
  final VesselSearchSource _vesselSearchSource;

  VesselRepositoryImpl(this._vesselSearchSource);

  @override
  Future<List<VesselSearchModel>> getVesselList({String? regDt, int? mmsi}) async {
    try {
      // DataSource는 Result를 반환하지만, Repository는 기존 인터페이스 유지
      final result = await _vesselSearchSource.getVesselList(
        regDt: regDt,
        mmsi: mmsi,
      );
      
      return result.fold(
        onSuccess: (vessels) => vessels,
        onFailure: (error) {
          logger.e('Vessel Repository Error: $error');
          // 에러 발생 시 빈 리스트 반환 (기존 동작 유지)
          // 또는 에러를 throw하려면: throw error;
          return [];
        },
      );
    } catch (e) {
      logger.e('Vessel Repository Error: $e');
      return [];
    }
  }
}
