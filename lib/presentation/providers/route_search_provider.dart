// lib/presentation/providers/route_search_provider.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/navigation/route_search_model.dart';
import 'package:vms_app/data/repositories/route_search_repository_impl.dart';

class RouteSearchProvider with ChangeNotifier {
  late final RouteSearchRepositoryImpl _routeSearchRepository;

  // 기존 변수들
  List<PastRouteSearchModel> _pastRouteList = [];
  List<PredRouteSearchModel> _predRouteList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // ✅ 추가된 변수
  bool _isNavigationHistoryMode = false;

  // 기존 getter들
  List<PastRouteSearchModel> get pastRouteList => _pastRouteList;
  List<PredRouteSearchModel> get predRouteList => _predRouteList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ✅ 추가된 getter들
  List<PastRouteSearchModel> get pastRoutes => _pastRouteList; // 별칭
  List<PredRouteSearchModel> get predRoutes => _predRouteList; // 별칭
  bool get isNavigationHistoryMode => _isNavigationHistoryMode;

  RouteSearchProvider() {
    // ✅ DI 컨테이너에서 주입
    _routeSearchRepository = getIt<RouteSearchRepositoryImpl>();
  }

  Future<void> getVesselRoute({String? regDt, int? mmsi}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _routeSearchRepository.getVesselRoute(
        regDt: regDt,
        mmsi: mmsi,
      );

      _pastRouteList = response.past;
      _predRouteList = response.pred;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ✅ 추가된 메서드들

  /// 항로 데이터 초기화
  void clearRoutes() {
    _pastRouteList = [];
    _predRouteList = [];
    _errorMessage = '';
    notifyListeners();
  }

  /// 항행 이력 모드 설정
  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    notifyListeners();
  }

  /// 과거 항로 데이터 설정 (필요한 경우)
  void setPastRoutes(List<PastRouteSearchModel> routes) {
    _pastRouteList = routes;
    notifyListeners();
  }

  /// 예측 항로 데이터 설정 (필요한 경우)
  void setPredRoutes(List<PredRouteSearchModel> routes) {
    _predRouteList = routes;
    notifyListeners();
  }

  /// 전체 데이터 리셋
  void reset() {
    _pastRouteList = [];
    _predRouteList = [];
    _isLoading = false;
    _errorMessage = '';
    _isNavigationHistoryMode = false;
    notifyListeners();
  }
}