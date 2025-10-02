// lib/presentation/providers/navigation_provider.dart
import 'package:flutter/material.dart';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation_usecases.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 항행이력 상태 관리 Provider
class NavigationProvider extends BaseProvider {
  // Use Cases
  late final GetNavigationHistory _getNavigationHistory;
  late final GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 캐시 매니저
  final SimpleCache _cache = SimpleCache();

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
      return '금일 항행경보가 없습니다.';
    }
    return _navigationWarnings.join('             ');
  }

  NavigationProvider() {
    try {
      _navigationRepository = getIt<NavigationRepository>();
      _getNavigationHistory = getIt<GetNavigationHistory>();
      _getWeatherInfo = getIt<GetWeatherInfo>();

      // 초기 데이터 로드
      getWeatherInfo();
      getNavigationWarnings();
    } catch (e) {
      AppLogger.e('NavigationProvider 초기화 실패: $e');
      setError('초기화 중 오류가 발생했습니다.');
    }
  }

  /// 항행이력 리스트 조회
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

    final cacheKey = 'ros_list_${startDate ?? "none"}_${endDate ?? "none"}_'
        '${mmsi ?? "all"}_${shipName ?? "none"}';

    // 캐시 확인
    final cachedData = _cache.get<List<NavigationModel>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 항행이력 리스트');
      _rosList = cachedData;
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 항행이력 리스트');

    final result = await executeAsync(() async {
      return await _getNavigationHistory.execute(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );
    }, errorMessage: '항행이력 조회 중 오류 발생');

    if (result != null) {
      _rosList = result;

      // 캐시 저장 (1시간)
      _cache.put(cacheKey, result, AppDurations.hours1);
      AppLogger.d('💾 [캐시 저장] 항행이력 리스트 (1시간 유효)');

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
      AppLogger.d('✅ [캐시 사용] 기상정보');
      _applyWeatherData(cachedData);
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 기상정보');

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

        // 캐시 저장 (30분)
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
        AppLogger.d('💾 [캐시 저장] 기상정보 (30분 유효)');

        safeNotifyListeners();
      }
    }, errorMessage: '기상정보 조회 중 오류 발생', showLoading: false);
  }

  /// 항행경보 조회
  Future<void> getNavigationWarnings() async {
    const cacheKey = 'navigation_warnings';

    // 캐시 확인
    final cachedData = _cache.get<List<String>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 항행경보');
      _navigationWarnings = cachedData;
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 항행경보');

    await executeAsync(() async {
      final result = await _navigationRepository.getNavigationWarnings();

      if (result != null && result.isNotEmpty) {
        _navigationWarnings = result;

        // 캐시 저장 (1시간)
        _cache.put(cacheKey, result, AppDurations.hours1);
        AppLogger.d('💾 [캐시 저장] 항행경보 (1시간 유효)');

        safeNotifyListeners();
      } else {
        _navigationWarnings = [];
        safeNotifyListeners();
      }
    }, errorMessage: '항행경보 조회 중 오류 발생', showLoading: false);
  }

  // ========== UI Helper 메서드들 ==========

  /// 파고 색상 반환
  /// 양호: 0~0.5m (흰색), 주의: 0.5~1.5m (주황색), 심각: 1.5m 이상 (붉은색)
  Color getWaveColor(double waveValue) {
    if (waveValue <= 0.5) {
      return getColorWhiteType1();
    } else if (waveValue <= 1.5) {
      return getColorEmergencyOrange();
    } else {
      return getColorRedType1();
    }
  }

  /// 시정 색상 반환
  /// 양호: 10km 이상 (흰색), 주의: 0.5~10km (주황색), 심각: 0.5km 이하 (붉은색)
  Color getVisibilityColor(double visibilityValue) {
    double visibilityInKm = visibilityValue / 1000.0;

    if (visibilityInKm >= 10.0) {
      return getColorWhiteType1();
    } else if (visibilityInKm > 0.5) {
      return getColorEmergencyOrange();
    } else {
      return getColorRedType1();
    }
  }

  /// 파고 상태 텍스트 반환
  String getFormattedWaveThresholdText(double waveValue) {
    String status = StringConstants.emptyString;
    Color color = getWaveColor(waveValue);

    if (color == getColorWhiteType1()) {
      status = "양호";
    } else if (color == getColorEmergencyOrange()) {
      status = "주의";
    } else {
      status = "심각";
    }

    return "${waveValue.toStringAsFixed(1)}m ($status)";
  }

  /// 시정 상태 텍스트 반환
  String getFormattedVisibilityThresholdText(double visibilityValue) {
    String status = StringConstants.emptyString;
    Color color = getVisibilityColor(visibilityValue);

    if (color == getColorWhiteType1()) {
      status = "양호";
    } else if (color == getColorEmergencyOrange()) {
      status = "주의";
    } else {
      status = "심각";
    }

    double visibilityInKm = visibilityValue / 1000;

    if (visibilityInKm >= 1) {
      return "${visibilityInKm.toStringAsFixed(1)}km ($status)";
    } else {
      return "${visibilityInKm.toStringAsFixed(2)}km ($status)";
    }
  }

  /// 캐시된 기상정보 적용
  void _applyWeatherData(Map<String, double> data) {
    wave = data['wave'] ?? NumericConstants.zeroValue.toDouble();
    visibility = data['visibility'] ?? NumericConstants.zeroValue.toDouble();
    walm1 = data['walm1'] ?? 0.0;
    walm2 = data['walm2'] ?? 0.0;
    walm3 = data['walm3'] ?? 0.0;
    walm4 = data['walm4'] ?? 0.0;
    valm1 = data['valm1'] ?? 0.0;
    valm2 = data['valm2'] ?? 0.0;
    valm3 = data['valm3'] ?? 0.0;
    valm4 = data['valm4'] ?? 0.0;
  }

  /// 데이터 새로고침
  Future<void> refreshData({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    clearError();
    await getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
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
    AppLogger.d('NavigationProvider disposed');
    super.dispose();
  }
}