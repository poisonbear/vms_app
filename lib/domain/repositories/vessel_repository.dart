import 'package:vms_app/data/models/vessel_model.dart';

abstract class VesselRepository {
  Future<List<VesselSearchModel>> getVesselList({String? regDt, int? mmsi});
}
