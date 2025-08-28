import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/navigation/route_search_model.dart';
import 'package:vms_app/domain/repositories/route_search_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class RouteSearchProvider extends BaseProvider {
  late final RouteSearchRepository _routeSearchRepository;

  List<PastRouteSearchModel> _pastRouteList = [];
  List<PredRouteSearchModel> _predRouteList = [];
  bool _isNavigationHistoryMode = false;

  // Getters
  List<PastRouteSearchModel> get pastRouteList => _pastRouteList;
  List<PredRouteSearchModel> get predRouteList => _predRouteList;
  List<PastRouteSearchModel> get pastRoutes => _pastRouteList;
  List<PredRouteSearchModel> get predRoutes => _predRouteList;
  bool get isNavigationHistoryMode => _isNavigationHistoryMode;

  RouteSearchProvider() {
    _routeSearchRepository = getIt<RouteSearchRepository>();
  }

  Future<void> getVesselRoute({String? regDt, int? mmsi}) async {
    final response = await executeAsync(() async {
      return await _routeSearchRepository.getVesselRoute(
        regDt: regDt,
        mmsi: mmsi,
      );
    }, errorMessage: '항로 조회 중 오류 발생');

    if (response != null) {
      _pastRouteList = response.past;
      _predRouteList = response.pred;
      notifyListeners();
    }
  }

  void clearRoutes() {
    _pastRouteList = [];
    _predRouteList = [];
    clearError();
    notifyListeners();
  }

  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    notifyListeners();
  }

  void setPastRoutes(List<PastRouteSearchModel> routes) {
    _pastRouteList = routes;
    notifyListeners();
  }

  void setPredRoutes(List<PredRouteSearchModel> routes) {
    _predRouteList = routes;
    notifyListeners();
  }

  void reset() {
    _pastRouteList = [];
    _predRouteList = [];
    _isNavigationHistoryMode = false;
    clearError();
    setLoading(false);
    notifyListeners();
  }
}
