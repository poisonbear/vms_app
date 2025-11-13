// lib/presentation/providers/weather_provider.dart
import 'dart:math';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 기상정보 Provider (LRU 캐싱 최적화)
class WeatherProvider extends BaseProvider {
  late final WeatherRepository _widRepository;

  //LRU 캐시 (자동 메모리 관리)
  final _cache = MemoryCache();

  List<WidModel>? _widList;
  final List<String> _windDirection = [];
  final List<String> _windSpeed = [];
  final List<String> _windIcon = [];

  // 캐시 통계
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // Getters
  List<WidModel>? get widList => _widList;
  List<WidModel>? get WidList => _widList; // 하위 호환성
  List<String> get windDirection => _windDirection;
  List<String> get windSpeed => _windSpeed;
  List<String> get windIcon => _windIcon;

  WeatherProvider() {
    _widRepository = getIt<WeatherRepository>();
    getWidList();
  }

  /// 기상정보 리스트 조회 (LRU 캐싱 최적화)
  ///
  /// - 캐시 유효 시간: 30분 (기상 데이터 갱신 주기 고려)
  /// - 30분 단위로 캐시 키 생성 (불필요한 API 호출 감소)
  Future<void> getWidList({bool forceRefresh = false}) async {
    final now = DateTime.now();
    //30분 단위로 캐시 키 생성
    final cacheKey =
        'wid_list_${now.year}${now.month}${now.day}_${now.hour}_${now.minute ~/ 30}';

    //강제 새로고침이 아닐 때만 캐시 확인 (로딩 상태 없이)
    if (!forceRefresh) {
      final cachedData = _cache.get<List<WidModel>>(cacheKey);
      if (cachedData != null) {
        _cacheHits++;
        AppLogger.d('[캐시 HIT] 기상정보 (hits: $_cacheHits)');
        AppLogger.d('캐시된 기상 데이터: ${cachedData.length}개');

        _widList = cachedData;
        _processWindData(cachedData);
        safeNotifyListeners();
        return; // 캐시 히트 시 즉시 리턴
      }
    }

    //캐시 미스 또는 강제 새로고침
    _cacheMisses++;
    AppLogger.d('[캐시 MISS] 기상정보 API 호출 (misses: $_cacheMisses)');

    final result = await executeAsync<List<WidModel>>(
      () async {
        return await _widRepository.getWidList();
      },
      errorMessage: '기상 정보 로드 중 오류 발생',
      showLoading: true,
    );

    //응답 처리 (executeAsync 밖에서)
    if (result != null && result.isNotEmpty) {
      _widList = result;
      _processWindData(result);

      // LRU 캐시 저장 (30분, 자동 메모리 관리)
      _cache.put(cacheKey, result, AppDurations.minutes30);
      AppLogger.d(' [캐시 저장] 기상정보 ${result.length}개 (30분 유효)');

      safeNotifyListeners();
    } else {
      AppLogger.w('[WARNING] API 응답이 null이거나 비어있습니다');
      _widList = null;
      safeNotifyListeners();
    }
  }

  /// 풍향/풍속 데이터 처리
  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();

    AppLogger.d(' === 풍향/풍속 데이터 처리 (8방위) ===');
    AppLogger.d('총 ${weatherList.length}개 기상 데이터 처리');

    for (int i = 0; i < weatherList.length; i++) {
      final weather = weatherList[i];
      _calculateWind(weather.wind_u_surface, weather.wind_v_surface);
    }

    AppLogger.d(' 풍향/풍속 계산 완료');
    _printAllWindData();
  }

  /// 풍향/풍속 계산 (기존 로직 유지)
  void _calculateWind(double? windU, double? windV) {
    if (windU == null || windV == null) {
      _windDirection.add('정온');
      _windSpeed.add('0');
      _windIcon.add('ro0');
      return;
    }

    // 풍속 계산 (m/s)
    final speed = sqrt(windU * windU + windV * windV);
    _windSpeed.add(speed.toStringAsFixed(NumericConstants.oneValue));

    // 풍속이 0.5 미만이면 정온
    if (speed < NumericConstants.movingSpeedThreshold) {
      _windDirection.add('정온');
      _windIcon.add('ro0');
      return;
    }

    // 풍향 계산 (라디안 -> 도)
    double degrees = atan2(windV, windU) * NumericConstants.i180 / pi;

    // 기상학적 풍향으로 변환 (바람이 불어오는 방향)
    degrees = (270 - degrees) % NumericConstants.i360;

    // 8방위 변환
    const directions = ['북', '북동', '동', '남동', '남', '남서', '서', '북서'];
    final index = ((degrees + NumericConstants.d22_5) / 45).floor() % 8;
    _windDirection.add(directions[index]);

    // 아이콘 회전 각도 (SVG 아이콘이 북쪽 기준일 때)
    final iconRotation =
        ((index * 45 + NumericConstants.i180) % NumericConstants.i360);
    _windIcon.add('ro$iconRotation');
  }

  /// 디버깅용 - 모든 풍향 데이터 출력
  void _printAllWindData() {
    AppLogger.d('');
    AppLogger.d('=== 전체 풍향/풍속 요약 ===');
    for (int i = 0; i < _windDirection.length; i++) {
      AppLogger.d(
          '[$i] ${_windDirection[i]} / ${_windSpeed[i]}m/s / ${_windIcon[i]}');
    }
    AppLogger.d('================================');
  }

  /// 캐시 통계 조회
  Map<String, dynamic> getCacheStatistics() {
    final total = _cacheHits + _cacheMisses;
    final hitRate =
        total > 0 ? (_cacheHits * 100 / total).toStringAsFixed(1) : '0.0';

    return {
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': '$hitRate%',
      'total': total,
      'weatherCount': _widList?.length ?? 0,
    };
  }

  ///캐시 상태 디버그 출력
  void printCacheStats() {
    final stats = getCacheStatistics();
    AppLogger.d('WeatherProvider 캐시 통계:');
    AppLogger.d('Hits: ${stats['hits']}, Misses: ${stats['misses']}');
    AppLogger.d('Hit Rate: ${stats['hitRate']}');
    AppLogger.d('기상 데이터: ${stats['weatherCount']}개');

    // MemoryCache 전체 통계
    _cache.printDebugInfo();
  }

  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    AppLogger.d('[CACHE] WeatherProvider 캐시 클리어');
  }

  /// 현재 날씨 (첫 번째 데이터)
  WidModel? get currentWeather =>
      _widList?.isNotEmpty == true ? _widList!.first : null;

  /// 평균 파고
  double get averageWaveHeight {
    if (_widList == null || _widList!.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final weather in _widList!) {
      if (weather.wave_height != null) {
        sum += weather.wave_height!;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  /// 현재 온도
  double? get currentTemperature => currentWeather?.current_temp;

  /// 현재 파고
  double? get currentWaveHeight => currentWeather?.wave_height;

  @override
  void dispose() {
    _widList?.clear();
    _widList = null;
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();
    clearCache();
    AppLogger.d('WeatherProvider disposed');
    super.dispose();
  }
}

// ============================================
// 하위 호환성을 위한 별칭
// ============================================
typedef WidWeatherInfoViewModel = WeatherProvider;
