import 'package:flutter/material.dart';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/cache_service.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation_usecases.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/navigation_model.dart';
import 'package:vms_app/core/constants/constants.dart'; // app_colors 포함

/// 항행이력 상태 관리 Provider - 타입 안전성 개선 버전
class NavigationProvider extends BaseProvider {
  // Use Cases
  late final GetNavigationHistory _getNavigationHistory;
  late final GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 캐시 매니저 - 메모리 캐시
  final SimpleCache _cache = SimpleCache();

  // State variables - 명확한 타입 정의
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

  // Getters - 타입 안전성 확보
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

  /// getRosList - 타입 안전성 확보
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

    final cacheKey = 'ros_list_${startDate ?? "none"}_${endDate ?? "none"}_'
        '${mmsi ?? "all"}_${shipName ?? "all"}';

    // 캐시 확인
    final cachedData = _cache.get<List<NavigationModel>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 항행 이력 데이터');
      _rosList = cachedData;
      safeNotifyListeners();
      return;
    }

    await executeAsync<void>(() async {
      _rosList = await _getNavigationHistory.execute(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
        shipName: shipName,
      );

      // 캐시에 저장 (10분간 유지)
      _cache.put(cacheKey, _rosList, const Duration(minutes: 10));
      AppLogger.d('✅ [API 호출] 항행 이력 데이터 (캐시 저장됨)');
      safeNotifyListeners();
    }, errorMessage: '항행 이력을 불러오는 중 오류가 발생했습니다');
  }

  /// 날씨 정보 조회 (시정/파고)
  Future<void> getWeatherInfo() async {
    try {
      final weatherInfo = await _getWeatherInfo.execute();

      if (weatherInfo != null) {
        // WeatherInfo의 필드들을 직접 할당
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

        AppLogger.d('🌊 wave: $wave, visibility: $visibility');
        safeNotifyListeners();
      }
    } catch (e) {
      AppLogger.e('날씨 정보 조회 실패: $e');
    }
  }

  /// 항행 경보 조회
  Future<void> getNavigationWarnings() async {
    try {
      final warnings = await _navigationRepository.getNavigationWarnings();

      if (warnings != null) {
        _navigationWarnings = warnings;
        AppLogger.d('✅ 항행 경보 업데이트: ${warnings.length}건');
        safeNotifyListeners();
      } else {
        _navigationWarnings = [];
      }
    } catch (e) {
      AppLogger.e('항행 경보 조회 실패: $e');
      _navigationWarnings = [];
    }
  }

  // ========== 날씨 관련 UI 메소드들 (수정됨) ==========

  /// 파고 색상 반환 - 수정된 기준
  /// 양호: 0~0.5m (흰색), 주의: 0.5~1.5m (주황색), 심각: 1.5m 이상 (붉은색)
  Color getWaveColor(double waveValue) {
    if (waveValue <= 0.5) {
      return getColorWhiteType1();       // 양호 (0~0.5m) - 흰색
    } else if (waveValue <= 1.5) {
      return getColorEmergencyOrange();  // 주의 (0.5~1.5m) - 주황색
    } else {
      return getColorRedType1();         // 심각 (1.5m 이상) - 빨간색
    }
  }

  /// 시정 색상 반환 - 수정된 기준
  /// 양호: 10km 이상 (흰색), 주의: 0.5~10km (주황색), 심각: 0.5km 이하 (붉은색)
  Color getVisibilityColor(double visibilityValue) {
    // visibilityValue는 미터 단위이므로 km로 변환
    double visibilityInKm = visibilityValue / 1000.0;

    if (visibilityInKm >= 10.0) {
      return getColorWhiteType1();       // 양호 (10km 이상) - 흰색
    } else if (visibilityInKm > 0.5) {
      return getColorEmergencyOrange();  // 주의 (0.5km 초과 ~ 10km 미만) - 주황색
    } else {
      return getColorRedType1();         // 심각 (0.5km 이하) - 빨간색
    }
  }

  /// 파고 상태 텍스트 반환
  String getFormattedWaveThresholdText(double waveValue) {
    String status = "";
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
    String status = "";
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

  /// 캐시 클리어 - 메모리와 영구 저장소 모두
  void clearCache() {
    _cache.clear();

    // 영구 캐시도 삭제
    CacheManager.clearCache('ros_list').catchError((e) {
      AppLogger.w('영구 캐시 삭제 실패: $e');
    });
    CacheManager.clearCache('weather_latest').catchError((e) {
      AppLogger.w('날씨 캐시 삭제 실패: $e');
    });
    CacheManager.clearCache('nav_warnings_latest').catchError((e) {
      AppLogger.w('경보 캐시 삭제 실패: $e');
    });

    AppLogger.d('🗑️ 모든 캐시 클리어 (메모리 + 영구)');
  }

  void clearSearch() {
    _rosList = [];
    clearError();
    notifyListeners();
  }

  Future<void> refresh({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    clearCache();
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

  @override
  void dispose() {
    // 리소스 정리
    _rosList.clear();
    _navigationWarnings.clear();
    _cache.clear();

    // BaseProvider의 dispose 호출
    super.dispose();
  }
}