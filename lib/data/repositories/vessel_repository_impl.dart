import 'package:vms_app/data/datasources/remote/vessel_remote_datasource.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';

class VesselRepositoryImpl implements VesselRepository {
  final VesselSearchSource _vesselSearchSource;

  // ✅ 생성자를 통한 의존성 주입
  VesselRepositoryImpl(this._vesselSearchSource);

  @override
  Future<List<VesselSearchModel>> getVesselList({String? regDt, int? mmsi}) {
    return _vesselSearchSource.getVesselList(regDt: regDt, mmsi: mmsi);
  }
}
