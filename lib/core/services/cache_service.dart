import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 통합 캐시 서비스 (기존 CacheService)
class CacheService {
  static CacheService? _instance;
  final Map<String, _CacheEntry> _memoryCache = {};

  static const String _persistentPrefix = 'cache_';
  static const String _timestampPrefix = 'cache_time_';

  Timer? _maintenanceTimer;
  DateTime? _lastCleanup;

  static const Map<String, int> cacheDurationMinutes = {
    'vessel_list': 5,
    'vessel_route': 10,
    'wid_list': 30,
    'ros_list': 30,
    'weather_info': 15,
    'navigation_warnings': 60,
    'user_info': 120,
    'holiday_info': 1440,
  };

  CacheService._() {
    _startMaintenanceTimer();
  }

  factory CacheService() {
    _instance ??= CacheService._();
    return _instance!;
  }

  void put(String key, dynamic data, Duration duration) {
    _memoryCache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );
    AppLogger.d('Memory cache saved: $key');
  }

  T? get<T>(String key) {
    final entry = _memoryCache[key];

    if (entry == null) return null;

    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  bool has(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return false;
    }
    return true;
  }

  void remove(String key) {
    _memoryCache.remove(key);
  }

  void clear() {
    _memoryCache.clear();
    AppLogger.d('Memory cache cleared');
  }

  void cleanExpired() {
    final keysToRemove = <String>[];
    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) {
        keysToRemove.add(key);
      }
    });
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      AppLogger.d('Cleaned ${keysToRemove.length} expired cache entries');
    }
  }

  static Future<void> saveCache(String key, dynamic data) async {
    CacheService().put(
      key,
      data,
      Duration(minutes: _getCacheDuration(key)),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('$_persistentPrefix$key', jsonData);
      await prefs.setString('$_timestampPrefix$key', DateTime.now().toIso8601String());
      AppLogger.d('Persistent cache saved: $key');
    } catch (e) {
      AppLogger.e('Failed to save persistent cache: $e');
    }
  }

  static Future<dynamic> getCache(String key) async {
    final memoryData = CacheService().get(key);
    if (memoryData != null) {
      return memoryData;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_persistentPrefix$key');
      final timestampString = prefs.getString('$_timestampPrefix$key');

      if (jsonString != null && timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        final duration = Duration(minutes: _getCacheDuration(key));

        if (DateTime.now().difference(timestamp) < duration) {
          final data = jsonDecode(jsonString);
          CacheService().put(key, data, duration - DateTime.now().difference(timestamp));
          return data;
        }
      }
    } catch (e) {
      AppLogger.e('Failed to get persistent cache: $e');
    }

    return null;
  }

  static Future<void> removeCache(String key) async {
    CacheService().remove(key);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_persistentPrefix$key');
      await prefs.remove('$_timestampPrefix$key');
    } catch (e) {
      AppLogger.e('Failed to remove persistent cache: $e');
    }
  }

  static Future<bool> hasCache(String key) async {
    if (CacheService().has(key)) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_persistentPrefix$key');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isCacheValid(String key) async {
    final data = await getCache(key);
    return data != null;
  }

  static Future<void> clearCache(String pattern) async {
    final instance = CacheService();

    final keysToRemove = instance._memoryCache.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      instance.remove(key);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) =>
      (key.startsWith(_persistentPrefix) || key.startsWith(_timestampPrefix)) &&
          key.contains(pattern)
      );

      for (final key in keys) {
        await prefs.remove(key);
      }

      AppLogger.d('Cache cleared for pattern: $pattern');
    } catch (e) {
      AppLogger.e('Failed to clear cache: $e');
    }
  }

  static Future<void> clearAllCache() async {
    CacheService().clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) =>
      key.startsWith(_persistentPrefix) || key.startsWith(_timestampPrefix)
      );

      for (final key in keys) {
        await prefs.remove(key);
      }

      AppLogger.d('All cache cleared');
    } catch (e) {
      AppLogger.e('Failed to clear all cache: $e');
    }
  }

  static Future<String> getCacheSize() async {
    final instance = CacheService();

    try {
      int memorySize = 0;
      instance._memoryCache.forEach((key, entry) {
        memorySize += jsonEncode(entry.data).length;
      });

      final prefs = await SharedPreferences.getInstance();
      int diskSize = 0;

      for (final key in prefs.getKeys()) {
        if (key.startsWith(_persistentPrefix)) {
          final data = prefs.getString(key);
          if (data != null) {
            diskSize += data.length;
          }
        }
      }

      final totalKB = ((memorySize + diskSize) / 1024).toStringAsFixed(2);
      return '${totalKB}KB';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _startMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      performMaintenance();
    });
  }

  void performMaintenance() {
    cleanExpired();
    _lastCleanup = DateTime.now();

    final stats = getStatistics();
    AppLogger.d('Cache maintenance completed: $stats');
  }

  void dispose() {
    _maintenanceTimer?.cancel();
    clear();
  }

  static int _getCacheDuration(String key) {
    final baseKey = _extractBaseKey(key);
    return cacheDurationMinutes[baseKey] ?? 30;
  }

  static String _extractBaseKey(String key) {
    for (final baseKey in cacheDurationMinutes.keys) {
      if (key.startsWith(baseKey)) {
        return baseKey;
      }
    }

    final parts = key.split('_');
    if (parts.length >= 2) {
      final candidate = '${parts[0]}_${parts[1]}';
      if (cacheDurationMinutes.containsKey(candidate)) {
        return candidate;
      }
    }

    return key;
  }

  Map<String, dynamic> getStatistics() {
    int activeCount = 0;
    int expiredCount = 0;
    final typeCount = <String, int>{};

    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        activeCount++;
      }

      final baseKey = _extractBaseKey(key);
      typeCount[baseKey] = (typeCount[baseKey] ?? 0) + 1;
    });

    return {
      'total': _memoryCache.length,
      'active': activeCount,
      'expired': expiredCount,
      'types': typeCount,
      'lastCleanup': _lastCleanup?.toIso8601String() ?? 'Never',
    };
  }
}

/// SimpleCache 클래스 - 하위 호환성 유지 (size getter 추가)
class SimpleCache {
  final CacheService _cacheService = CacheService();

  void put(String key, dynamic data, Duration duration) {
    _cacheService.put(key, data, duration);
  }

  T? get<T>(String key) {
    return _cacheService.get<T>(key);
  }

  bool has(String key) {
    return _cacheService.has(key);
  }

  void remove(String key) {
    _cacheService.remove(key);
  }

  void clear() {
    _cacheService.clear();
  }

  void cleanExpired() {
    _cacheService.cleanExpired();
  }

  /// size getter 추가
  int get size => _cacheService._memoryCache.length;
}

/// CacheManager 클래스 - 하위 호환성 유지
class CacheManager {
  CacheManager._();

  static Future<void> saveCache(String key, dynamic data) async {
    return CacheService.saveCache(key, data);
  }

  static Future<dynamic> getCache(String key) async {
    return CacheService.getCache(key);
  }

  static Future<void> removeCache(String key) async {
    return CacheService.removeCache(key);
  }

  static Future<bool> hasCache(String key) async {
    return CacheService.hasCache(key);
  }

  static Future<bool> isCacheValid(String key) async {
    return CacheService.isCacheValid(key);
  }

  static Future<void> clearAllCache() async {
    return CacheService.clearAllCache();
  }

  static Future<void> clearCache(String pattern) async {
    return CacheService.clearCache(pattern);
  }

  static Future<String> getCacheSize() async {
    return CacheService.getCacheSize();
  }
}

/// 캐시 엔트리
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({
    required this.data,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// 타이머 서비스 - 하위 호환성 유지
class TimerService {
  final Map<String, Timer> _timers = {};
  final Map<String, StreamController> _streamControllers = {};

  // 타이머 이름 상수
  static const String WEATHER_UPDATE = 'weather_update';
  static const String ROUTE_UPDATE = 'route_update';
  static const String VESSEL_UPDATE = 'vessel_update';
  static const String autoRefresh = 'auto_refresh';
  static const String locationUpdate = 'location_update';
  static const String weatherUpdate = 'weather_update';
  static const String vesselTracking = 'vessel_tracking';
  static const String sessionTimeout = 'session_timeout';

  void startTimer({
    required String name,
    required Duration duration,
    required VoidCallback callback,
    bool immediate = false,
  }) {
    cancelTimer(name);

    if (immediate) {
      callback();
    }

    _timers[name] = Timer.periodic(duration, (_) {
      try {
        callback();
      } catch (e) {
        AppLogger.e('Timer error ($name): $e');
      }
    });

    AppLogger.d('Timer started: $name (${duration.inSeconds}s)');
  }

  void startOnceTimer({
    required String name,
    required Duration duration,
    required VoidCallback callback,
  }) {
    cancelTimer(name);

    _timers[name] = Timer(duration, () {
      try {
        callback();
        _timers.remove(name);
      } catch (e) {
        AppLogger.e('Timer error ($name): $e');
      }
    });

    AppLogger.d('Once timer started: $name (${duration.inSeconds}s)');
  }

  void startPeriodicTimer(String name, Duration duration, VoidCallback callback) {
    startTimer(name: name, duration: duration, callback: callback);
  }

  // startPeriodicTimer 오버로드 (명명된 매개변수 지원)
  void startPeriodicTimerNamed({
    required String timerId,
    required Duration duration,
    required VoidCallback callback,
  }) {
    startTimer(name: timerId, duration: duration, callback: callback);
  }

  void stopTimer(String name) {
    cancelTimer(name);
  }

  void cancelTimer(String name) {
    _timers[name]?.cancel();
    _timers.remove(name);
    _streamControllers[name]?.close();
    _streamControllers.remove(name);
    AppLogger.d('Timer cancelled: $name');
  }

  void stopAllTimers() {
    cancelAll();
  }

  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();

    AppLogger.d('All timers cancelled');
  }

  bool isActive(String name) {
    return _timers[name]?.isActive ?? false;
  }

  void dispose() {
    cancelAll();
  }

  Map<String, dynamic> getStatistics() {
    return {
      'active': _timers.keys.where((key) => _timers[key]?.isActive ?? false).toList(),
      'total': _timers.length,
      'streams': _streamControllers.keys.toList(),
    };
  }
}

/// PopupService - 하위 호환성 유지
class PopupService {
  static final Map<String, bool> _activePopups = {};
  static final Map<String, Completer> _popupCompleters = {};

  // 팝업 타입 상수
  static const String TURBINE_ENTRY_ALERT = 'turbine_entry_alert';
  static const String WEATHER_ALERT = 'weather_alert';
  static const String SUBMARINE_CABLE_ALERT = 'submarine_cable_alert';
  static const String emergencyPopup = 'emergency';
  static const String warningPopup = 'warning';
  static const String infoPopup = 'info';
  static const String confirmPopup = 'confirm';

  // 인스턴스 메서드로 전환
  bool isPopupActive(String type) {
    return _activePopups[type] ?? false;
  }

  void showPopup(String type) {
    _activePopups[type] = true;
    AppLogger.d('Popup $type: shown');
  }

  void hidePopup(String type) {
    _activePopups[type] = false;
    AppLogger.d('Popup $type: hidden');
  }

  void dispose() {
    _activePopups.clear();
    _popupCompleters.clear();
  }

  // 정적 메서드들 (기존 호환성)
  static Future<void> showInfoPopup(
      BuildContext context, {
        required String title,
        required String message,
        String buttonText = '확인',
      }) async {
    if (_isPopupActive(infoPopup)) return;

    _setPopupActive(infoPopup, true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPopupActive(infoPopup, false);
              },
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmPopup(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = '확인',
        String cancelText = '취소',
      }) async {
    if (_isPopupActive(confirmPopup)) return false;

    _setPopupActive(confirmPopup, true);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _setPopupActive(confirmPopup, false);
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _setPopupActive(confirmPopup, false);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  static void showSnackBar(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  static bool _isPopupActive(String type) {
    return _activePopups[type] ?? false;
  }

  static void _setPopupActive(String type, bool active) {
    _activePopups[type] = active;
    AppLogger.d('Popup $type: ${active ? "shown" : "hidden"}');
  }

  static void closeAllPopups(BuildContext context) {
    int popCount = 0;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == '/') {
        return true;
      }
      popCount++;
      return false;
    });

    _activePopups.clear();
    AppLogger.d('Closed $popCount popups');
  }

  static void reset() {
    _activePopups.clear();
    _popupCompleters.clear();
  }
}

/// LocationFocusService - 하위 호환성 유지
class LocationFocusService {
  MapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _focusedLocation;
  final bool _isTracking = false;
  final bool _isAutoFocusEnabled = false;
  StreamSubscription<Position>? _positionSubscription;
  Function(LatLng)? _onLocationUpdate;
  Function(String)? _onError;

  static const LatLng defaultLocation = LatLng(35.374509, 126.132268);
  static const double defaultZoom = 13.0;
  static const double detailZoom = 16.0;
  static const double overviewZoom = 10.0;

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  LatLng? get currentLocation => _currentLocation;
  LatLng? get focusedLocation => _focusedLocation;
  bool get isTracking => _isTracking;
  bool get isAutoFocusEnabled => _isAutoFocusEnabled;

  Future<bool> focusToCurrentLocation({
    double? zoom,
    bool animate = true,
  }) async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _onError?.call('위치 권한이 필요합니다');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _focusedLocation = _currentLocation;

      if (_mapController != null && _currentLocation != null) {
        moveToLocation(_currentLocation!, zoom: zoom);
      }

      _onLocationUpdate?.call(_currentLocation!);
      AppLogger.d('Focused to current location: $_currentLocation');
      return true;
    } catch (e) {
      AppLogger.e('Failed to focus to current location: $e');
      _onError?.call('현재 위치를 가져올 수 없습니다');
      return false;
    }
  }

  void moveToLocation(LatLng location, {double? zoom}) {
    _mapController?.move(location, zoom ?? defaultZoom);
  }

  Future<bool> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return requested != LocationPermission.denied &&
          requested != LocationPermission.deniedForever;
    }
    return permission != LocationPermission.deniedForever;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}

// StateManager는 별도 파일(state_manager.dart)에 있음 - 여기서 제거

/// MemoryManager - 하위 호환성 유지
class MemoryManager {
  final List<VoidCallback> _disposables = [];
  final Map<String, dynamic> _resources = {};

  void register(VoidCallback disposable) {
    _disposables.add(disposable);
  }

  void addResource(String key, dynamic resource) {
    _resources[key] = resource;
  }

  T? getResource<T>(String key) {
    return _resources[key] as T?;
  }

  void removeResource(String key) {
    _resources.remove(key);
  }

  void disposeAll() {
    for (final disposable in _disposables) {
      try {
        disposable();
      } catch (e) {
        AppLogger.e('Error disposing resource: $e');
      }
    }
    _disposables.clear();
    _resources.clear();
    AppLogger.d('All resources disposed');
  }

  void clear() {
    _resources.clear();
  }

  Map<String, dynamic> getStatistics() {
    return {
      'disposables': _disposables.length,
      'resources': _resources.keys.toList(),
    };
  }
}

/// 캐시 상태 모니터링 유틸리티
class CacheMonitor {
  static final _cache = SimpleCache();

  /// 캐시 상태 로깅
  static void logCacheStatus(String prefix) {
    AppLogger.d('======= 캐시 상태 ($prefix) =======');
    AppLogger.d('캐시 시스템 활성화됨');
    AppLogger.d('캐시 크기: ${_cache.size} 항목');
    AppLogger.d('================================');
  }

  /// 특정 키의 캐시 존재 여부 확인
  static bool isCached(String key) {
    final data = _cache.get(key);
    return data != null;
  }

  /// 캐시 통계
  static Map<String, dynamic> getCacheStats() {
    return {
      'system': 'SimpleCache',
      'status': 'active',
      'size': _cache.size,
      'features': [
        '선박 목록 캐싱 (5분)',
        '선박 경로 캐싱 (10분)',
        '날씨 정보 캐싱 (15분)',
        '기상정보 리스트 캐싱 (30분)',
        '항행이력 캐싱 (30분)',
        '항행경보 캐싱 (60분)',
      ],
    };
  }
}

/// 앱 초기화 관리자 (간소화 버전)
class AppInitializer {
  AppInitializer._();

  /// 간단한 앱 초기화
  static Future<void> initialize() async {
    try {
      AppLogger.d('Starting app initialization...');

      // 1. Flutter 바인딩 초기화
      WidgetsFlutterBinding.ensureInitialized();

      // 2. 캐시 서비스 초기화
      final cacheService = CacheService();
      cacheService.cleanExpired();

      // 3. 캐시 통계 로깅
      final stats = cacheService.getStatistics();
      AppLogger.d('Cache initialized: $stats');

      AppLogger.d('App initialization completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('App initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// 보안 초기화 (간소화 버전)
  static Future<void> initializeSecurity() async {
    try {
      AppLogger.d('Initializing security...');
      // 보안 관련 초기화 로직을 여기에 추가
      // 예: 인증서 검증, 루트 탐지 등
      AppLogger.d('Security initialization completed');
    } catch (e) {
      AppLogger.e('Security initialization failed: $e');
      // 보안 초기화 실패해도 앱은 계속 실행
    }
  }

  /// 앱 종료시 정리 작업
  static Future<void> cleanup() async {
    AppLogger.d('Starting app cleanup...');

    try {
      // 캐시 정리
      final cacheService = CacheService();
      cacheService.dispose();

      // 타이머 정리
      final timerService = TimerService();
      timerService.dispose();

      AppLogger.d('App cleanup completed');
    } catch (e) {
      AppLogger.e('App cleanup failed: $e');
    }
  }
}