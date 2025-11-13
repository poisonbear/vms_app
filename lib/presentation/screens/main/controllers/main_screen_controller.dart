import 'package:flutter/material.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/presentation/services/services.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'dart:async';

/// MainScreen의 모든 상태와 로직을 관리하는 컨트롤러
class MainScreenController extends ChangeNotifier {
  // Services
  late final TimerService timerService;
  late final PopupService popupService;
  late final LocationFocusService locationFocusService;
  late final StateManager stateManager;
  final MemoryManager memoryManager = MemoryManager();

  // Map Controller
  final MapController mapController = MapController();

  // Route Search
  late RouteProvider _routeSearchViewModel;

  // State variables
  int? _selectedVesselMmsi;
  bool _isTrackingEnabled = false;
  bool _isOtherVesselsVisible = true;
  bool _isFlashing = false;
  LatLng? _currentPosition;
  int _selectedIndex = 0;

  // dispose 상태 추적
  bool _isDisposed = false;

  // Stream subscriptions 관리
  final List<StreamSubscription> _subscriptions = [];

  // Timer 관리
  final Map<String, Timer> _activeTimers = {};

  // Getters
  bool get isTrackingEnabled => _isTrackingEnabled;
  bool get isOtherVesselsVisible => _isOtherVesselsVisible;
  bool get isFlashing => _isFlashing;
  LatLng? get currentPosition => _currentPosition;
  int get selectedIndex => _selectedIndex;
  int? get selectedVesselMmsi => _selectedVesselMmsi;
  RouteProvider get routeSearchViewModel => _routeSearchViewModel;
  bool get isDisposed => _isDisposed;

  MainScreenController({RouteProvider? routeSearchViewModel}) {
    timerService = TimerService();
    popupService = PopupService();
    locationFocusService = LocationFocusService();
    stateManager = StateManager();
    _routeSearchViewModel = routeSearchViewModel ?? RouteProvider();

    AppLogger.d('MainScreenController initialized');
  }

  /// 초기화
  void initialize() {
    // 타이머 시작 등 초기화 로직
    notifyListeners();
  }

  /// 안전한 notifyListeners 호출
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// 트래킹 시작 (기존 메서드)
  void startTracking(int mmsi) {
    if (_isDisposed) return;

    _selectedVesselMmsi = mmsi;
    _isTrackingEnabled = true;
    _safeNotifyListeners();

    AppLogger.d('Tracking started for MMSI: $mmsi');
  }

  /// 트래킹 중지 (기존 메서드)
  void stopTracking() {
    if (_isDisposed) return;

    _selectedVesselMmsi = null;
    _isTrackingEnabled = false;

    // RouteSearchProvider의 경로 초기화
    _routeSearchViewModel.clearRoutes();
    _routeSearchViewModel.setNavigationHistoryMode(false);

    _safeNotifyListeners();

    AppLogger.d('Tracking stopped');
  }

  /// 다른 선박 표시 토글 (기존 메서드)
  void toggleOtherVesselsVisibility() {
    if (_isDisposed) return;

    _isOtherVesselsVisible = !_isOtherVesselsVisible;
    _safeNotifyListeners();

    AppLogger.d('Other vessels visibility: $_isOtherVesselsVisible');
  }

  /// 홈으로 이동 (기존 메서드)
  void moveToHome() {
    if (_isDisposed) return;

    try {
      mapController.moveAndRotate(
        const LatLng(35.374509, 126.132268), // 기본 홈 위치
        12.0, // 줌 레벨
        0.0, // 회전 각도
      );
      AppLogger.d('Moved to home position');
    } catch (e) {
      AppLogger.e('Failed to move to home: $e');
    }
  }

  /// 네비게이션 히스토리 리셋 (수정된 메서드)
  void resetNavigationHistory() {
    if (_isDisposed) return;

    stopTracking(); // 트래킹 중지
    _selectedIndex = 0;
    _safeNotifyListeners();

    AppLogger.d('Navigation history reset');
  }

  /// 선박 MMSI 설정
  void setSelectedVesselMmsi(int? mmsi) {
    if (_isDisposed) return;

    if (_selectedVesselMmsi != mmsi) {
      _selectedVesselMmsi = mmsi;
      _safeNotifyListeners();
      AppLogger.d('Selected vessel MMSI: $mmsi');
    }
  }

  /// 추적 모드 토글
  void toggleTracking() {
    if (_isDisposed) return;

    _isTrackingEnabled = !_isTrackingEnabled;
    _safeNotifyListeners();
    AppLogger.d('Tracking ${_isTrackingEnabled ? "enabled" : "disabled"}');
  }

  /// 다른 선박 표시 토글 (새 버전 - 기존과 호환)
  void toggleOtherVessels() {
    toggleOtherVesselsVisibility();
  }

  /// 플래싱 시작
  void startFlashing() {
    if (_isDisposed) return;

    _isFlashing = true;
    _safeNotifyListeners();
  }

  /// 플래싱 중지
  void stopFlashing() {
    if (_isDisposed) return;

    _isFlashing = false;
    _safeNotifyListeners();
  }

  /// 현재 위치 업데이트
  void updateCurrentPosition(LatLng position) {
    if (_isDisposed) return;

    _currentPosition = position;
    _safeNotifyListeners();
  }

  /// 선택된 인덱스 설정
  void setSelectedIndex(int index) {
    if (_isDisposed) return;

    if (_selectedIndex != index) {
      _selectedIndex = index;
      _safeNotifyListeners();
    }
  }

  /// 특정 위치로 이동
  void moveToLocation(LatLng location, double zoom) {
    if (_isDisposed) return;

    try {
      mapController.move(location, zoom);
      AppLogger.d('Moved to location: $location, zoom: $zoom');
    } catch (e) {
      AppLogger.e('Failed to move to location: $e');
    }
  }

  /// 타이머 추가 및 관리
  void addTimer(String key, Timer timer) {
    if (_isDisposed) return;

    // 기존 타이머가 있으면 취소
    cancelTimer(key);

    _activeTimers[key] = timer;
    AppLogger.d('Timer added: $key');
  }

  /// 타이머 취소
  void cancelTimer(String key) {
    final timer = _activeTimers[key];
    if (timer != null) {
      timer.cancel();
      _activeTimers.remove(key);
      AppLogger.d('Timer cancelled: $key');
    }
  }

  /// 모든 타이머 취소
  void cancelAllTimers() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    AppLogger.d('All timers cancelled');
  }

  /// Stream subscription 추가
  void addSubscription(StreamSubscription subscription) {
    if (_isDisposed) return;

    _subscriptions.add(subscription);
    AppLogger.d('Stream subscription added');
  }

  /// Stream subscription 제거
  void removeSubscription(StreamSubscription subscription) {
    _subscriptions.remove(subscription);
    subscription.cancel();
    AppLogger.d('Stream subscription removed');
  }

  /// 모든 Stream subscriptions 취소
  Future<void> cancelAllSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    AppLogger.d('All stream subscriptions cancelled');
  }

  /// 주기적 업데이트 시작
  void startPeriodicUpdates() {
    if (_isDisposed) return;

    // 선박 업데이트 타이머
    final vesselTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!_isDisposed) {
          // 선박 데이터 업데이트 로직
          AppLogger.d('Vessel update timer fired');
        }
      },
    );
    addTimer('vessel_update', vesselTimer);

    // 날씨 업데이트 타이머
    final weatherTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) {
        if (!_isDisposed) {
          // 날씨 데이터 업데이트 로직
          AppLogger.d('Weather update timer fired');
        }
      },
    );
    addTimer('weather_update', weatherTimer);

    // 경로 업데이트 타이머
    final routeTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_isDisposed && _selectedVesselMmsi != null) {
          // 경로 데이터 업데이트 로직
          AppLogger.d('Route update timer fired');
        }
      },
    );
    addTimer('route_update', routeTimer);
  }

  /// 주기적 업데이트 중지
  void stopPeriodicUpdates() {
    cancelTimer('vessel_update');
    cancelTimer('weather_update');
    cancelTimer('route_update');
    AppLogger.d('Periodic updates stopped');
  }

  /// 리소스 정리 (dispose 전 호출)
  Future<void> cleanup() async {
    if (_isDisposed) return;

    AppLogger.d('Starting MainScreenController cleanup...');

    try {
      // 1. 타이머 정지
      stopPeriodicUpdates();
      cancelAllTimers();

      // 2. TimerService 정리
      timerService.stopTimer(TimerService.WEATHER_UPDATE);
      timerService.stopTimer(TimerService.ROUTE_UPDATE);
      timerService.stopTimer(TimerService.VESSEL_UPDATE);
      timerService.stopAllTimers();

      // 3. Stream subscriptions 취소
      await cancelAllSubscriptions();

      // 4. 상태 초기화
      _selectedVesselMmsi = null;
      _isTrackingEnabled = false;
      _isOtherVesselsVisible = true;
      _isFlashing = false;
      _currentPosition = null;
      _selectedIndex = 0;

      AppLogger.d('MainScreenController cleanup completed');
    } catch (e) {
      AppLogger.e('Error during cleanup: $e');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      AppLogger.w('MainScreenController already disposed');
      return;
    }

    _isDisposed = true;
    AppLogger.d('Disposing MainScreenController...');

    // 비동기 cleanup을 동기적으로 처리
    cleanup().then((_) {
      try {
        // 각 서비스 dispose
        timerService.dispose();
        popupService.dispose();
        locationFocusService.dispose();
        stateManager.dispose();
        memoryManager.disposeAll();

        AppLogger.d('MainScreenController disposed successfully');
      } catch (e) {
        AppLogger.e('Error during service disposal: $e');
      }
    }).catchError((error) {
      AppLogger.e('Cleanup error during disposal: $error');
    });

    super.dispose();
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    if (_isDisposed) {
      AppLogger.w('Controller is disposed');
      return;
    }

    AppLogger.d('=== MainScreenController Debug Info ===');
    AppLogger.d('IsDisposed: $_isDisposed');
    AppLogger.d('Selected MMSI: $_selectedVesselMmsi');
    AppLogger.d('Tracking Enabled: $_isTrackingEnabled');
    AppLogger.d('Other Vessels Visible: $_isOtherVesselsVisible');
    AppLogger.d('Is Flashing: $_isFlashing');
    AppLogger.d('Current Position: $_currentPosition');
    AppLogger.d('Selected Index: $_selectedIndex');
    AppLogger.d('Active Timers: ${_activeTimers.keys.join(", ")}');
    AppLogger.d('Active Subscriptions: ${_subscriptions.length}');
    AppLogger.d('=====================================');
  }
}

/// MapControllerProvider (navigation_tab.dart에서 사용)
class MapControllerProvider extends ChangeNotifier {
  final MapController mapController = MapController();
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  void moveToPoint(LatLng point, double zoom) {
    if (_isDisposed) return;

    try {
      mapController.move(point, zoom);
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to move map: $e');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    AppLogger.d('MapControllerProvider disposed');
    super.dispose();
  }
}
