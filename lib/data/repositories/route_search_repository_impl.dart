import 'package:vms_app/data/datasources/remote/route_search_remote_datasource.dart';
import 'package:vms_app/data/models/navigation/vessel_route_model.dart';

class RouteSearchRepositoryImpl {
  final RouteSearchSource _routeSearchSource;

  // ✅ 생성자를 통한 의존성 주입
  RouteSearchRepositoryImpl(this._routeSearchSource);

  Future<VesselRouteResponse> getVesselRoute({String? regDt, int? mmsi}) {
    return _routeSearchSource.getVesselRoute(regDt: regDt, mmsi: mmsi);
  }
}