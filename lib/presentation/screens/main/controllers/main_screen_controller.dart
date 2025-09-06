// lib/presentation/screens/main/controllers/main_screen_controller.dart

import 'package:flutter/material.dart';
import 'package:vms_app/core/services/timer_service.dart';
import 'package:vms_app/core/services/popup_service.dart';
import 'package:vms_app/core/services/location_focus_service.dart';
import 'package:vms_app/core/services/state_manager.dart';
import 'package:vms_app/core/services/memory_manager.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// MainScreen의 모든 상태와 로직을 관리하는 컨트롤러
class MainScreenController extends ChangeNotifier {
  // Services - public으로 변경
  late final TimerService timerService;
  late final PopupService popupService;
  late final LocationFocusService locationFocusService;
  late final StateManager stateManager;
  final MemoryManager memoryManager = MemoryManager();
  
  // Map Controller
  final MapController mapController = MapController();
  
  // Route Search
  late RouteSearchProvider _routeSearchViewModel;
  
  // State variables
  int? _selectedVesselMmsi;
  bool _isTrackingEnabled = false;
  bool _isOtherVesselsVisible = true;
  bool _isFlashing = false;
  LatLng? _currentPosition;
  int _selectedIndex = 0;
  
  // Getters
  bool get isTrackingEnabled => _isTrackingEnabled;
  bool get isOtherVesselsVisible => _isOtherVesselsVisible;
  bool get isFlashing => _isFlashing;
  LatLng? get currentPosition => _currentPosition;
  int get selectedIndex => _selectedIndex;
  int? get selectedVesselMmsi => _selectedVesselMmsi;
  RouteSearchProvider get routeSearchViewModel => _routeSearchViewModel;
  
  MainScreenController({RouteSearchProvider? routeSearchViewModel}) {
    timerService = TimerService();
    popupService = PopupService();
    locationFocusService = LocationFocusService();
    stateManager = StateManager();
    _routeSearchViewModel = routeSearchViewModel ?? RouteSearchProvider();
  }
  
  /// 초기화
  void initialize() {
    // 타이머 시작 등 초기화 로직
    notifyListeners();
  }
  
  /// 다른 선박 표시 토글
  void toggleOtherVesselsVisibility() {
    _isOtherVesselsVisible = !_isOtherVesselsVisible;
    notifyListeners();
  }
  
  /// 현재 위치 업데이트
  void updateCurrentPosition(LatLng position) {
    _currentPosition = position;
    notifyListeners();
  }
  
  /// 트래킹 시작
  void startTracking(int mmsi) {
    _selectedVesselMmsi = mmsi;
    _isTrackingEnabled = true;
    notifyListeners();
  }
  
  /// 트래킹 중지
  void stopTracking() {
    _selectedVesselMmsi = null;
    _isTrackingEnabled = false;
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);
    notifyListeners();
  }
  
  /// 플래싱 시작
  void startFlashing() {
    _isFlashing = true;
    notifyListeners();
  }
  
  /// 플래싱 중지
  void stopFlashing() {
    _isFlashing = false;
    notifyListeners();
  }
  
  /// 네비게이션 히스토리 리셋
  void resetNavigationHistory() {
    stopTracking();
    _selectedIndex = 0;
    notifyListeners();
  }
  
  /// 선택된 인덱스 변경
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
  
  /// 홈으로 이동
  void moveToHome() {
    mapController.moveAndRotate(
      const LatLng(35.374509, 126.132268),
      12.0,
      0.0,
    );
  }
  
  /// 특정 위치로 이동
  void moveToLocation(LatLng location, double zoom) {
    mapController.move(location, zoom);
  }
  
  @override
  void dispose() {
    timerService.dispose();
    popupService.dispose();
    locationFocusService.dispose();
    stateManager.dispose();
    memoryManager.disposeAll();
    timerService.stopTimer(TimerService.WEATHER_UPDATE);
    timerService.stopTimer(TimerService.ROUTE_UPDATE);
    timerService.stopTimer(TimerService.VESSEL_UPDATE);
    super.dispose();
  }
}

// MapControllerProvider를 여기에 추가 (navigation_tab.dart에서 사용)
class MapControllerProvider extends ChangeNotifier {
  final MapController mapController = MapController();

  void moveToPoint(LatLng point, double zoom) {
    mapController.move(point, zoom);
  }
}
