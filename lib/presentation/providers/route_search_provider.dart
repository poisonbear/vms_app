import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/navigation/route_search_model.dart';
import 'package:vms_app/domain/repositories/route_search_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class RouteSearchProvider extends BaseProvider {
  late final RouteSearchRepository _routeSearchRepository;

  // 기존 구조 유지
  List<PastRouteSearchModel> _pastRouteList = [];
  List<PredRouteSearchModel> _predRouteList = [];
  bool _isNavigationHistoryMode = false;

  // Getters - 기존 코드에서 사용하는 모든 프로퍼티 지원
  List<PastRouteSearchModel> get pastRouteList => _pastRouteList;
  List<PredRouteSearchModel> get predRouteList => _predRouteList;
  List<PastRouteSearchModel> get pastRoutes => _pastRouteList; // 기존 코드용
  List<PredRouteSearchModel> get predRoutes => _predRouteList; // 기존 코드용
  bool get isNavigationHistoryMode => _isNavigationHistoryMode; // 기존 코드용

  RouteSearchProvider() {
    _routeSearchRepository = getIt<RouteSearchRepository>();
  }

  // 기존 메서드 유지
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

  // 기존 코드에서 사용하는 메서드들
  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    notifyListeners();
  }

  void clearRoutes() {
    _pastRouteList = [];
    _predRouteList = [];
    _isNavigationHistoryMode = false;
    clearError();
    notifyListeners();
  }

  // 추가 utility 메서드들
  void setPastRoutes(List<PastRouteSearchModel> routes) {
    _pastRouteList = routes;
    notifyListeners();
  }

  void setPredRoutes(List<PredRouteSearchModel> routes) {
    _predRouteList = routes;
    notifyListeners();
  }

  bool get hasData => _pastRouteList.isNotEmpty || _predRouteList.isNotEmpty;

  void reset() {
    _pastRouteList = [];
    _predRouteList = [];
    _isNavigationHistoryMode = false;
    clearError();
    setLoading(false);
    notifyListeners();
  }

  @override
  void dispose() {
    // Route 검색 관련 리소스 정리
    clearRoutes();
    _isNavigationHistoryMode = false;

    // BaseProvider의 dispose 호출
    super.dispose();
  }
}
