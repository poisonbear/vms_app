import 'package:flutter/material.dart';
import 'package:vms_app/data/models/navigation/route_search_model.dart';
import 'package:vms_app/data/datasources/remote/route_search_remote_datasource.dart';

class RouteSearchProvider with ChangeNotifier {
  final RouteSearchSource _routeSearchSource = RouteSearchSource();

  bool _isLoading = false;
  String _errorMessage = '';
  List<PastRouteSearchModel> _pastRoutes = [];
  List<PredRouteSearchModel> _predRoutes = [];
  bool _isNavigationHistoryMode = false;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<PastRouteSearchModel> get pastRoutes => _pastRoutes;
  List<PredRouteSearchModel> get predRoutes => _predRoutes;
  bool get isNavigationHistoryMode => _isNavigationHistoryMode;

  RouteSearchProvider();

  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    notifyListeners();
  }

  Future<void> getVesselRoute({
    String? regDt,
    int? mmsi,
    bool includePrediction = true,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _routeSearchSource.getVesselRoute(
        regDt: regDt,
        mmsi: mmsi,
      );

      _pastRoutes = response.past;
      _predRoutes = includePrediction ? response.pred : [];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearRoutes() {
    _pastRoutes = [];
    _predRoutes = [];
    _errorMessage = '';
    notifyListeners();
  }

  void reset() {
    _pastRoutes = [];
    _predRoutes = [];
    _errorMessage = '';
    _isNavigationHistoryMode = false;
    _isLoading = false;
    notifyListeners();
  }
}
