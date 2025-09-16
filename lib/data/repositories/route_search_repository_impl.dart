import 'package:vms_app/data/datasources/remote/route_search_remote_datasource.dart';
import 'package:vms_app/data/models/navigation/vessel_route_model.dart';
import 'package:vms_app/domain/repositories/route_search_repository.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class RouteSearchRepositoryImpl implements RouteSearchRepository {
  final RouteSearchSource _dataSource;

  RouteSearchRepositoryImpl(this._dataSource);

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
