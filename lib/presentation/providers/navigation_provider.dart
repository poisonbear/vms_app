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

    // 캐시 확인 (로딩 상태 없이)
    final cachedData = _cache.get<List<NavigationModel>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 HIT] 항행이력 리스트');
      _rosList = cachedData;
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [캐시 MISS] 항행이력 리스트 API 호출');

    // API 호출
    final result = await executeAsync<List<NavigationModel>>(
      () async {
        return await _getNavigationHistory.execute(
          startDate: startDate,
          endDate: endDate,
          mmsi: mmsi,
          shipName: shipName,
        );
      },
      errorMessage: ErrorMessages.navigationLoadFailed,
      showLoading: true,
    );

    // 응답 처리
    if (result != null && result.isNotEmpty) {
      _rosList = result;

      // LRU 캐시 저장 (1시간)
      _cache.put(cacheKey, result, AppDurations.hours1);
      AppLogger.d('💾 [캐시 저장] 항행이력 ${result.length}개 (1시간 유효)');

      safeNotifyListeners();
    } else {
      AppLogger.w('[WARNING] API 응답이 null이거나 비어있습니다');
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
      AppLogger.d('✅ [캐시 HIT] 기상정보');
      _applyWeatherData(cachedData);
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [캐시 MISS] 기상정보 API 호출');

    // API 호출
    final result = await executeAsync<WeatherInfo?>(
      () async {
        return await _getWeatherInfo.execute();
      },
      errorMessage: ErrorMessages.weatherInfoLoadFailed,
      showLoading: false,
    );

    // 응답 처리
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
      AppLogger.d('💾 [캐시 저장] 기상정보 (30분 유효)');

      safeNotifyListeners();
    } else {
      AppLogger.w('[WARNING] 기상정보 응답이 null입니다');
    }
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
      AppLogger.d('✅ [캐시 HIT] 항행경보');
      _navigationWarnings = cachedData;
      safeNotifyListeners();
      return;
    }

    AppLogger.d('🔄 [캐시 MISS] 항행경보 API 호출');

    // API 호출
    final result = await executeAsync<List<String>?>(
      () async {
        return await _getNavigationWarnings.execute();
      },
      errorMessage: ErrorMessages.navigationWarningsLoadFailed,
      showLoading: false,
    );

    // 응답 처리 및 데이터 가공 (Key 제거)
    if (result != null && result.isNotEmpty) {
      // 각 항목에서 Key를 제거하고 순수 메시지만 추출
      _navigationWarnings = result.map((item) {
        return _extractWarningMessage(item);
      }).toList();

      // LRU 캐시 저장 (1시간)
      _cache.put(cacheKey, _navigationWarnings, AppDurations.hours1);
      AppLogger.d('💾 [캐시 저장] 항행경보 ${_navigationWarnings.length}개 (1시간 유효)');

      safeNotifyListeners();
    } else {
      AppLogger.d('[INFO] 항행경보가 없거나 응답이 null입니다');
      _navigationWarnings = [];
      safeNotifyListeners();
    }
  }

  /// 항행경보 메시지에서 Key 제거
  String _extractWarningMessage(dynamic item) {
    // 이미 문자열인 경우
    if (item is String) {
      // 문자열에 중괄호가 포함되어 있으면 Map.toString() 형태
      if (item.contains('{') && item.contains('}')) {
        // 정규식으로 message 필드 값 추출
        final messagePattern = RegExp(r'message[:\s]+([^,}]+)');
        final match = messagePattern.firstMatch(item);

        if (match != null && match.group(1) != null) {
          return match.group(1)!.trim();
        }

        // message가 없으면 첫 번째 값 추출
        final valuePattern = RegExp(r':\s*([^,}]+)');
        final matches = valuePattern.allMatches(item);

        if (matches.isNotEmpty) {
          return matches.first.group(1)?.trim() ?? item;
        }
      }
      // 정상적인 문자열이면 그대로 반환
      return item;
    }

    // Map 형식인 경우 - 실제 API 응답
    if (item is Map) {
      // 우선순위: message > area_nm > title > subject > content
      final message = item['message'] ??
          item['area_nm'] ??
          item['title'] ??
          item['subject'] ??
          item['content'] ??
          item['text'] ??
          item['description'];

      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }

      // Map의 첫 번째 값 사용 (fallback)
      if (item.values.isNotEmpty) {
        return item.values.first?.toString() ?? '항행경보';
      }
    }

    // Model 객체인 경우 (getter 시도)
    try {
      if (item.message != null) return item.message.toString();
      if (item.area_nm != null) return item.area_nm.toString();
      if (item.title != null) return item.title.toString();
      if (item.subject != null) return item.subject.toString();
      if (item.content != null) return item.content.toString();
    } catch (e) {
      // getter가 없으면 무시
      AppLogger.d('항행경보 메시지 추출 실패: $e');
    }

    // 모든 시도가 실패하면 기본 메시지
    return '항행경보';
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
