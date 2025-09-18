import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart' as weather_usecase;
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 항행이력 상태 관리 Provider (구조적 개선 버전 - 모든 기능 유지)
class NavigationProvider extends BaseProvider {
  // Use Cases
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 캐시 매니저 - 기존에 이미 있던 것
  final SimpleCache _cache = SimpleCache();

  // State variables - 기존 구조 완전히 유지
  List<dynamic> _rosList = [];
  bool _isInitialized = false;
  List<String> _navigationWarnings = [];

  // Weather data - 기존 public 변수 모두 유지
  double wave = 0;
  double visibility = 0;
  double walm1 = 0.0;
  double walm2 = 0.0;
  double walm3 = 0.0;
  double walm4 = 0.0;
  double valm1 = 0.0;
  double valm2 = 0.0;
  double valm3 = 0.0;
  double valm4 = 0.0;

  // 기존 getters 모두 유지
  List<dynamic> get rosList => _rosList;
  List<dynamic> get RosList => _rosList; // 하위 호환성
  bool get isInitialized => _isInitialized;
  List<String> get navigationWarnings => _navigationWarnings;

  // 기존 combinedNavigationWarnings 유지
  String get combinedNavigationWarnings {
    if (_navigationWarnings.isEmpty) {
      return '금일 항행경보가 없습니다.';
    }
    return _navigationWarnings.join('             ');
  }

  // 기존 생성자 로직 유지 + 에러 처리 개선
  NavigationProvider() {
    try {
      _navigationRepository = getIt<NavigationRepository>();
      _getNavigationHistory = getIt<GetNavigationHistory>();
      _getWeatherInfo = getIt<weather_usecase.GetWeatherInfo>();

      // 초기 데이터 로드 - 기존 로직 유지
      getWeatherInfo();
      getNavigationWarnings();
    } catch (e) {
      AppLogger.e('NavigationProvider 초기화 실패: $e');
      // 초기화 실패 시에도 앱이 동작하도록 처리
      setError('초기화 중 오류가 발생했습니다.');
    }
  }

  // getRosList - 기존 캐싱 로직 유지 + 개선
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

    // 기존 캐시 키 생성 로직 유지
    final cacheKey = 'ros_list_${startDate ?? "none"}_${endDate ?? "none"}_'
        '${mmsi ?? "all"}_${shipName ?? "all"}';

    // 기존 캐시 확인 로직 유지
    final cachedData = _cache.get<List<dynamic>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 항행이력 리스트');
      AppLogger.d('📊 캐시 데이터: ${cachedData.length}건');
      _rosList = cachedData;
      notifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 항행이력 리스트');
    AppLogger.d('📋 파라미터: startDate=$startDate, endDate=$endDate, mmsi=$mmsi, shipName=$shipName');

    // 기존 executeAsync 사용 유지
    final result = await executeAsync(() async {
      return await _getNavigationHistory.execute(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );
    }, errorMessage: '데이터 로드 중 오류 발생');

    if (result != null) {
      _rosList = result;

      // 기존 캐시 저장 로직 유지 (1시간)
      _cache.put(cacheKey, result, const Duration(hours: 1));
      AppLogger.d('💾 [캐시 저장] 항행이력 리스트 (1시간 유효)');
      AppLogger.d('📊 저장된 데이터: ${result.length}건');

      notifyListeners();
    } else {
      AppLogger.w('⚠️ [API 실패] 결과가 null');
      _rosList = [];
      notifyListeners();
    }
  }

  // getWeatherInfo - 기존 로직 완전히 유지
  Future<void> getWeatherInfo() async {
    AppLogger.d('getWeatherInfo 호출됨');

    // 기존 캐시 키 생성 로직 유지 (10분 단위)
    final now = DateTime.now();
    final cacheKey = 'weather_${now.hour}_${now.minute ~/ 10}';

    // 기존 캐시 확인 로직 유지
    final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 날씨 정보');
      // 기존 캐시 데이터 복원 로직 유지
      wave = cachedData['wave'] ?? 0;
      visibility = cachedData['visibility'] ?? 0;
      walm1 = cachedData['walm1'] ?? 0.0;
      walm2 = cachedData['walm2'] ?? 0.0;
      walm3 = cachedData['walm3'] ?? 0.0;
      walm4 = cachedData['walm4'] ?? 0.0;
      valm1 = cachedData['valm1'] ?? 0.0;
      valm2 = cachedData['valm2'] ?? 0.0;
      valm3 = cachedData['valm3'] ?? 0.0;
      valm4 = cachedData['valm4'] ?? 0.0;

      AppLogger.d('🌊 wave: $wave, visibility: $visibility');
      notifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 날씨 정보');

    // 기존 executeAsync 사용 유지
    final weatherInfo = await executeAsync(
          () => _getWeatherInfo.execute(),
      errorMessage: '기상 정보 로드 중 오류',
      showLoading: false,
    );

    if (weatherInfo != null) {
      // 기존 데이터 할당 로직 유지
      wave = weatherInfo.wave;
      visibility = weatherInfo.visibility;
      walm1 = weatherInfo.walm1;
      walm2 = weatherInfo.walm2;
      walm3 = weatherInfo.walm3;
      walm4 = weatherInfo.walm4;
      valm1 = weatherInfo.valm1;
      valm2 = weatherInfo.valm2;
      valm3 = weatherInfo.valm3;
      valm4 = weatherInfo.valm4;

      // 기존 캐시 저장 로직 유지
      final dataToCache = {
        'wave': wave,
        'visibility': visibility,
        'walm1': walm1,
        'walm2': walm2,
        'walm3': walm3,
        'walm4': walm4,
        'valm1': valm1,
        'valm2': valm2,
        'valm3': valm3,
        'valm4': valm4,
      };

      _cache.put(cacheKey, dataToCache, const Duration(minutes: 10));
      AppLogger.d('💾 [캐시 저장] 날씨 정보 (10분간 유효)');

      notifyListeners();
    }
  }

  // getNavigationWarnings - 기존 로직 완전히 유지
  Future<void> getNavigationWarnings() async {
    // 기존 캐시 키 생성 로직 유지 (시간별)
    final cacheKey = 'nav_warnings_${DateTime.now().hour}';

    // 기존 캐시 확인 로직 유지
    final cached = _cache.get<List<String>>(cacheKey);
    if (cached != null) {
      AppLogger.d('✅ [캐시 사용] 항행경보');
      _navigationWarnings = cached;
      notifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 항행경보');

    // 기존 executeAsync 사용 유지
    final warnings = await executeAsync(
          () => _navigationRepository.getNavigationWarnings(),
      errorMessage: '항행경보 로드 중 오류',
      showLoading: false,
    );

    if (warnings != null) {
      _navigationWarnings = warnings;

      // 기존 캐시 저장 로직 유지 (30분)
      _cache.put(cacheKey, warnings, const Duration(minutes: 30));
      AppLogger.d('💾 [캐시 저장] 항행경보 (30분간 유효)');

      notifyListeners();
    }
  }

  // 기존 Color 반환 메서드들 - 완전히 유지
  Color getWaveColor(double waveValue) {
    if (waveValue <= walm1) return Colors.green;
    if (waveValue <= walm2) return Colors.yellow;
    if (waveValue <= walm3) return Colors.orange;
    return Colors.red;
  }

  Color getVisibilityColor(double visibilityValue) {
    if (visibilityValue >= valm1) return Colors.green;
    if (visibilityValue >= valm2) return Colors.yellow;
    if (visibilityValue >= valm3) return Colors.orange;
    return Colors.red;
  }

  // 파고 임계값 텍스트 포맷팅 - m 단위 통일
  String getFormattedWaveThresholdText(double waveValue) {
    String status = "";
    Color color = getWaveColor(waveValue);

    if (color == Colors.green) {
      status = "양호";
    } else if (color == Colors.yellow) {
      status = "주의";
    } else if (color == Colors.orange) {
      status = "경계";
    } else {
      status = "위험";
    }

    return "${waveValue.toStringAsFixed(1)}m ($status)";
  }

  // 시정 임계값 텍스트 포맷팅 - km 단위 통일
  String getFormattedVisibilityThresholdText(double visibilityValue) {
    String status = "";
    Color color = getVisibilityColor(visibilityValue);

    if (color == Colors.green) {
      status = "양호";
    } else if (color == Colors.yellow) {
      status = "주의";
    } else if (color == Colors.orange) {
      status = "경계";
    } else {
      status = "위험";
    }

    // 모든 값을 km 단위로 통일
    double visibilityInKm = visibilityValue / 1000;

    // 1km 이상이면 소수점 1자리, 미만이면 소수점 2자리
    if (visibilityInKm >= 1) {
      return "${visibilityInKm.toStringAsFixed(1)}km ($status)";
    } else {
      return "${visibilityInKm.toStringAsFixed(2)}km ($status)";
    }
  }

  // 기존 clearCache 메서드 유지
  void clearCache() {
    _cache.clear();
    AppLogger.d('🗑️ 모든 캐시 클리어');
  }

  // ========== 구조적 개선 추가 메서드 (기존 기능 보완) ==========

  // 검색 초기화 메서드 추가 (UI에서 활용)
  void clearSearch() {
    _rosList = [];
    clearError();
    notifyListeners();
  }

  // 새로고침 메서드 추가 (강제 새로고침 지원)
  Future<void> refresh({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    // 캐시 클리어
    clearCache();

    // 병렬 새로고침
    await Future.wait([
      getRosList(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      ),
      getWeatherInfo(),
      getNavigationWarnings(),
    ]);
  }

  // 상태 체크 메서드 추가 (디버깅용)
  void debugPrintState() {
    AppLogger.d('=== NavigationProvider State ===');
    AppLogger.d('isInitialized: $_isInitialized');
    AppLogger.d('rosList count: ${_rosList.length}');
    AppLogger.d('isLoading: $isLoading');
    AppLogger.d('hasError: $hasError');
    AppLogger.d('wave: $wave, visibility: $visibility');
    AppLogger.d('warnings: ${_navigationWarnings.length}');
    AppLogger.d('cache size: ${_cache.size}');
    AppLogger.d('================================');
  }

  // 메모리 최적화를 위한 dispose 개선
  @override
  void dispose() {
    clearCache();
    _rosList.clear();
    _navigationWarnings.clear();
    AppLogger.d('NavigationProvider disposed');
    super.dispose();
  }
}

// ========== 기존 SimpleCache 클래스 유지 + 개선 ==========
class SimpleCache {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _timestamps = {};

  // 캐시 저장
  void put(String key, dynamic value, Duration duration) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now().add(duration);
  }

  // 캐시 가져오기 (만료 체크)
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    final expiry = _timestamps[key];
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      // 만료된 캐시 제거
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }

    return _cache[key] as T?;
  }

  // 캐시 존재 여부
  bool has(String key) {
    return _cache.containsKey(key);
  }

  // 캐시 제거
  void remove(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  // 전체 캐시 초기화
  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  // 캐시 크기
  int get size => _cache.length;

  // 만료된 캐시 자동 제거
  void cleanExpired() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _timestamps.forEach((key, expiry) {
      if (now.isAfter(expiry)) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      remove(key);
    }
  }
}