import 'package:vms_app/data/models/vessel_model.dart';

abstract class RouteSearchRepository {
  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi,
  });
}
