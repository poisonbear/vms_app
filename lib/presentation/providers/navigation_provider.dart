// lib/presentation/providers/navigation_provider.dart
import 'package:flutter/material.dart';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation_usecases.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

class NavigationProvider extends BaseProvider {
  // Use Cases
  late final GetNavigationHistory _getNavigationHistory;
  late final GetWeatherInfo _getWeatherInfo;
  late final GetNavigationWarnings _getNavigationWarnings;
  late final NavigationRepository _navigationRepository;

  final _cache = MemoryCache();

  // State variables
  List<NavigationModel> _rosList = [];
  bool _isInitialized = false;
  List<String> _navigationWarnings = [];

  // Weather data
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

  // Getters
  List<NavigationModel> get rosList => _rosList;
  bool get isInitialized => _isInitialized;
  List<String> get navigationWarnings => _navigationWarnings;

  String get combinedNavigationWarnings {
    if (_navigationWarnings.isEmpty) {
      return InfoMessages.noNavigationWarningsToday;
    }
    return _navigationWarnings.join('             ');
  }

  NavigationProvider() {
    try {
      _navigationRepository = getIt<NavigationRepository>();
      _getNavigationHistory = getIt<GetNavigationHistory>();
      _getWeatherInfo = getIt<GetWeatherInfo>();
      _getNavigationWarnings = getIt<GetNavigationWarnings>();

      // 초기 데이터 로드
      getWeatherInfo();
      getNavigationWarnings();
    } catch (e) {
      AppLogger.e('NavigationProvider 초기화 실패: $e');
      setError(ErrorMessages.initializationFailed);
    }
  }

  /// 항행이력 리스트 조회 (LRU 캐싱)
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

    // 캐시 키 생성
    final cacheKey = 'ros_list_${startDate ?? "none"}_${endDate ?? "none"}_'
        '${mmsi ?? "all"}_${shipName ?? "none"}';

    // 캐시 확인 (LRU 자동 적용)
    final cachedData = _cache.get<List<NavigationModel>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 HIT] 항행이력 리스트');
      _rosList = cachedData;
      safeNotifyListeners();
      return;
    }

    AppLogger.d('[캐시 MISS] 항행이력 리스트 API 호출');

    final result = await executeAsync(() async {
      return await _getNavigationHistory.execute(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );
    }, errorMessage: ErrorMessages.navigationLoadFailed);

    if (result != null) {
      _rosList = result;

      // LRU 캐시 저장 (1시간)
      _cache.put(cacheKey, result, AppDurations.hours1);
      AppLogger.d('[캐시 저장] 항행이력 ${result.length}개 (1시간 유효)');

      safeNotifyListeners();
    } else {
      _rosList = [];
      safeNotifyListeners();
    }
  }

  /// 기상정보 조회 (시정/파고)
  Future<void> getWeatherInfo() async {
    const cacheKey = 'weather_info';

    // 캐시 확인
    final cachedData = _cache.get<Map<String, double>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('[캐시 HIT] 기상정보');
      _applyWeatherData(cachedData);
      safeNotifyListeners();
      return;
    }

    AppLogger.d('[캐시 MISS] 기상정보 API 호출');

    await executeAsync(() async {
      final result = await _getWeatherInfo.execute();

      if (result != null) {
        wave = result.wave ?? NumericConstants.zeroValue.toDouble();
        visibility = result.visibility ?? NumericConstants.zeroValue.toDouble();
        walm1 = result.walm1 ?? 0.0;
        walm2 = result.walm2 ?? 0.0;
        walm3 = result.walm3 ?? 0.0;
        walm4 = result.walm4 ?? 0.0;
        valm1 = result.valm1 ?? 0.0;
        valm2 = result.valm2 ?? 0.0;
        valm3 = result.valm3 ?? 0.0;
        valm4 = result.valm4 ?? 0.0;

        // LRU 캐시 저장 (30분)
        final weatherData = {
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
        _cache.put(cacheKey, weatherData, AppDurations.minutes30);
        AppLogger.d('[캐시 저장] 기상정보 (30분 유효)');

        safeNotifyListeners();
      }
    }, errorMessage: ErrorMessages.weatherInfoLoadFailed, showLoading: false);
  }

  /// 캐시된 기상 데이터 적용
  void _applyWeatherData(Map<String, double> data) {
    wave = data['wave'] ?? 0.0;
    visibility = data['visibility'] ?? 0.0;
    walm1 = data['walm1'] ?? 0.0;
    walm2 = data['walm2'] ?? 0.0;
    walm3 = data['walm3'] ?? 0.0;
    walm4 = data['walm4'] ?? 0.0;
    valm1 = data['valm1'] ?? 0.0;
    valm2 = data['valm2'] ?? 0.0;
    valm3 = data['valm3'] ?? 0.0;
    valm4 = data['valm4'] ?? 0.0;
  }

  /// 항행경보 조회
  Future<void> getNavigationWarnings() async {
    const cacheKey = 'navigation_warnings';

    // 캐시 확인
    final cachedData = _cache.get<List<String>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('[캐시 HIT] 항행경보');
      _navigationWarnings = cachedData;
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [캐시 MISS] 항행경보 API 호출');

    await executeAsync(() async {
      final result = await _getNavigationWarnings.execute();

      if (result != null && result.isNotEmpty) {
        _navigationWarnings = result;

        // LRU 캐시 저장 (1시간)
        _cache.put(cacheKey, result, AppDurations.hours1);
        AppLogger.d('[캐시 저장] 항행경보 ${result.length}개 (1시간 유효)');

        safeNotifyListeners();
      } else {
        _navigationWarnings = [];
        safeNotifyListeners();
      }
    },
        errorMessage: ErrorMessages.navigationWarningsLoadFailed,
        showLoading: false);
  }

  // ========== UI Helper 메서드들 ==========

  /// 파고 색상 반환
  Color getWaveColor(double waveValue) {
    if (waveValue <= 0.5) {
      return AppColors.whiteType1;
    } else if (waveValue <= 1.5) {
      return AppColors.emergencyOrange;
    } else {
      return AppColors.redType1;
    }
  }

  /// 시정 색상 반환
  Color getVisibilityColor(double visibilityValue) {
    double visibilityInKm = visibilityValue / 1000.0;

    if (visibilityInKm >= 10.0) {
      return AppColors.whiteType1;
    } else if (visibilityInKm > 0.5) {
      return AppColors.emergencyOrange;
    } else {
      return AppColors.redType1;
    }
  }

  /// 파고 상태 텍스트
  String getWaveStatusText(double waveValue) {
    if (waveValue <= 0.5) return '양호';
    if (waveValue <= 1.5) return '주의';
    return '심각';
  }

  /// 시정 상태 텍스트
  String getVisibilityStatusText(double visibilityValue) {
    double visibilityInKm = visibilityValue / 1000.0;
    if (visibilityInKm >= 10.0) return '양호';
    if (visibilityInKm > 0.5) return '주의';
    return '심각';
  }

  /// 파고 임계값 텍스트 (포맷팅)
  String getFormattedWaveThresholdText(double waveValue) {
    return '${waveValue.toStringAsFixed(1)}m';
  }

  /// 시정 임계값 텍스트 (포맷팅)
  String getFormattedVisibilityThresholdText(double visibilityValue) {
    double visibilityInKm = visibilityValue / 1000.0;
    if (visibilityInKm >= 10.0) {
      return '${visibilityInKm.toStringAsFixed(1)}km';
    } else {
      return '${visibilityValue.toStringAsFixed(0)}m';
    }
  }

  /// 캐시 상태 디버그 출력
  void printCacheStats() {
    AppLogger.d('📊 NavigationProvider 캐시 통계:');
    _cache.printDebugInfo();
  }

  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
    AppLogger.d('[CACHE] NavigationProvider 캐시 클리어');
  }

  @override
  void dispose() {
    _rosList.clear();
    _navigationWarnings.clear();
    clearCache();
    AppLogger.d('NavigationProvider disposed');
    super.dispose();
  }
}
