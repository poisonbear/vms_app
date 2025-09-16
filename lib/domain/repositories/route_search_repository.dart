import 'package:vms_app/data/models/navigation/vessel_route_model.dart';

abstract class RouteSearchRepository {
  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi,
  });
}
