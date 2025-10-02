// lib/presentation/providers/weather_provider.dart
import 'dart:math';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 기상정보 Provider (캐싱 통합 버전)
class WeatherProvider extends BaseProvider {
  late final WeatherRepository _widRepository;
  final _cache = SimpleCache();

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

  /// 기상정보 리스트 조회 (캐싱 포함)
  Future<void> getWidList({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cacheKey = 'wid_list_${now.hour}_${now.minute ~/ NumericConstants.i30}';

    // 캐시 확인 (강제 새로고침이 아닐 때만)
    if (!forceRefresh) {
      final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        _cacheHits++;
        AppLogger.d('✅ [캐시 사용] 기상정보 리스트 (hits: $_cacheHits)');
        AppLogger.d('📦 캐시 데이터 타입: ${cachedData['widList'].runtimeType}');

        if (cachedData['widList'] != null) {
          try {
            _widList = cachedData['widList'] as List<WidModel>?;
            AppLogger.d('📊 _widList 길이: ${_widList?.length}');

            if (_widList != null && _widList!.isNotEmpty) {
              AppLogger.d('🌡️ 첫 데이터 온도: ${_widList!.first.current_temp}');
              AppLogger.d('🌊 첫 데이터 파고: ${_widList!.first.wave_height}');
            }

            _processWindData(_widList!);
            safeNotifyListeners();
            return;
          } catch(e) {
            AppLogger.e('❌ 캐시 복원 에러: $e');
            AppLogger.e('❌ 타입 캐스팅 실패, API 재호출 필요');
          }
        }
      }
    }

    // API 호출
    _cacheMisses++;
    AppLogger.d('🔄 [API 호출] 기상정보 리스트 (misses: $_cacheMisses)');

    final result = await executeAsync(() async {
      return await _widRepository.getWidList();
    }, errorMessage: '기상 정보 로드 중 오류 발생');

    if (result != null) {
      _widList = result;
      _processWindData(result);

      AppLogger.d('💾 저장 전 _widList 타입: ${_widList.runtimeType}');
      AppLogger.d('💾 저장 전 _widList 길이: ${_widList?.length}');

      // 캐시 저장
      final dataToCache = {
        'widList': result,
      };

      _cache.put(cacheKey, dataToCache, AppDurations.minutes30);
      AppLogger.d('💾 [캐시 저장] 기상정보 리스트 (30분간 유효)');
      safeNotifyListeners();
    }
  }

  /// 풍향/풍속 데이터 처리
  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();

    AppLogger.d('🌪️ === 풍향/풍속 데이터 처리 (8방위) ===');
    AppLogger.d('총 ${weatherList.length}개 기상 데이터 처리');
    AppLogger.d('');

    for (int i = 0; i < weatherList.length; i++) {
      final weather = weatherList[i];
      _calculateWind(weather.wind_u_surface, weather.wind_v_surface);
    }

    AppLogger.d('🌪️ 풍향/풍속 계산 완료');
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
    final iconRotation = ((index * 45 + NumericConstants.i180) % NumericConstants.i360);
    _windIcon.add('ro$iconRotation');
  }

  /// 디버깅용 - 모든 풍향 데이터 출력
  void _printAllWindData() {
    AppLogger.d('');
    AppLogger.d('📋 === 전체 풍향/풍속 요약 ===');
    for (int i = 0; i < _windDirection.length; i++) {
      AppLogger.d('[$i] ${_windDirection[i]} / ${_windSpeed[i]}m/s / ${_windIcon[i]}');
    }
    AppLogger.d('================================');
    AppLogger.d('');
  }

  /// 캐시 통계 조회
  Map<String, dynamic> getCacheStatistics() {
    final total = _cacheHits + _cacheMisses;
    return {
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': total > 0 ? (_cacheHits * 100 ~/ total) : 0,
      'total': total,
    };
  }

  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
    AppLogger.d('[CACHE] WeatherProvider 캐시 클리어');
  }

  /// 현재 날씨 (첫 번째 데이터)
  WidModel? get currentWeather => _widList?.isNotEmpty == true ? _widList!.first : null;

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
    _cache.clear();
    AppLogger.d('WeatherProvider disposed');
    super.dispose();
  }
}

// ============================================
// 하위 호환성을 위한 별칭
// ============================================
typedef WidWeatherInfoViewModel = WeatherProvider;