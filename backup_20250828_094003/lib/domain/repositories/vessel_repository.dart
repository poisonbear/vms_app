import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

abstract class VesselRepository {
  Future<List<VesselSearchModel>> getVesselList({
    String? regDt,
    int? mmsi,
  });
}
