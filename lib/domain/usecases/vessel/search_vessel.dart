import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/data/models/vessel_model.dart';

class SearchVesselParams {
  final String? regDt;
  final int? mmsi;

  SearchVesselParams({this.regDt, this.mmsi});
}

class SearchVessel {
  final VesselRepository repository;

  SearchVessel(this.repository);

  Future<List<VesselSearchModel>> execute(SearchVesselParams params) async {
    return await repository.getVesselList(
      regDt: params.regDt,
      mmsi: params.mmsi,
    );
  }
}
