import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/cache_service.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

import 'dart:math';

class WeatherProviderCached extends BaseProvider {
  late final WeatherRepository _weatherRepository;
  final _cache = SimpleCache();
  
  List<WidModel> _weatherList = [];
  List<WidModel> get weatherList => _weatherList;
  
  // 풍향/풍속 계산 결과 저장
  final List<String> _windDirection = [];
  final List<String> _windSpeed = [];
  final List<String> _windIcon = [];
  
  List<String> get windDirection => _windDirection;
  List<String> get windSpeed => _windSpeed;
  List<String> get windIcon => _windIcon;
  
  // 캐시 통계
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  WeatherProviderCached() {
    _weatherRepository = getIt<WeatherRepository>();
  }
  
  Future<void> loadWeatherData({bool forceRefresh = false}) async {
    const cacheKey = 'weather_data';
    const cacheDuration = Duration(minutes: 10);
    
    // 강제 새로고침이 아니면 캐시 확인
    if (!forceRefresh) {
      // 메모리 캐시 확인
      final cached = _cache.get<List<WidModel>>(cacheKey);
      if (cached != null) {
        _weatherList = cached;
        _processWindData(cached);
        _cacheHits++;
        AppLogger.d('✅ Weather from cache (hits: $_cacheHits)');
        notifyListeners();
        return;
      }
      
      // 영구 캐시 확인
      final persistentCached = await CacheManager.getCache(cacheKey);
      if (persistentCached != null) {
        try {
          _weatherList = (persistentCached as List)
              .map((json) => WidModel.fromJson(json))
              .toList();
          
          _processWindData(_weatherList);
          
          // 메모리 캐시 갱신
          _cache.put(cacheKey, _weatherList, cacheDuration);
          _cacheHits++;
          notifyListeners();
          return;
        } catch (e) {
          AppLogger.d('캐시 복원 실패, API 호출로 진행');
        }
      }
    }
    
    // API 호출
    _cacheMisses++;
    AppLogger.d('🔄 Loading weather from API (misses: $_cacheMisses)');
    
    final result = await executeAsync(
      () => _weatherRepository.getWidList(),
      errorMessage: '날씨 정보 로드 실패',
    );
    
    if (result != null) {
      _weatherList = result;
      _processWindData(result);
      
      // 메모리 캐시 저장
      _cache.put(cacheKey, _weatherList, cacheDuration);
      
      // 영구 캐시 저장 - WidModel의 실제 속성 사용
      try {
        final dataToCache = _weatherList.map((w) => {
          'weathercondition': w.weather_condition,
          'currenttemp': w.current_temp,
          'past3hprecipsurface': w.past3hprecip_surface,
          'windusurface': w.wind_u_surface,
          'windvsurface': w.wind_v_surface,
          'gustsurface': w.gust_surface,
          'waveheight': w.wave_height,
          'ptypesurface': w.ptype_surface,
          'timestamp': w.ts?.toIso8601String(),
          'regdt': w.reg_dt?.toIso8601String(),
        }).toList();
        
        await CacheManager.saveCache(cacheKey, dataToCache);
      } catch (e) {
        AppLogger.d('영구 캐시 저장 스킵: $e');
      }
      
      notifyListeners();
    }
  }
  
  /// 풍향/풍속 데이터 처리
  void _processWindData(List<WidModel> weatherList) {
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();
    
    for (final weather in weatherList) {
      _calculateWind(weather.wind_u_surface, weather.wind_v_surface);
    }
  }
  
  /// 풍향/풍속 계산
  void _calculateWind(double? windU, double? windV) {
    if (windU == null || windV == null) {
      _windDirection.add('정온');
      _windSpeed.add('0');
      _windIcon.add('ro0');
      return;
    }
    
    // 풍속 계산 (m/s)
    final speed = sqrt(windU * windU + windV * windV);
    _windSpeed.add(speed.toStringAsFixed(1));
    
    // 풍속이 0.5 미만이면 정온
    if (speed < 0.5) {
      _windDirection.add('정온');
      _windIcon.add('ro0');
      return;
    }
    
    // 풍향 계산 (라디안 -> 도)
    double degrees = atan2(windV, windU) * 180 / pi;
    
    // 기상학적 풍향으로 변환 (바람이 불어오는 방향)
    degrees = (270 - degrees) % 360;
    
    // 8방위 변환
    final directions = ['북', '북동', '동', '남동', '남', '남서', '서', '북서'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    _windDirection.add(directions[index]);
    
    // 아이콘 회전 각도 (SVG 아이콘이 북쪽 기준일 때)
    final iconRotation = ((index * 45 + 180) % 360);
    _windIcon.add('ro$iconRotation');
  }
  
  /// 캐시 통계
  Map<String, dynamic> getCacheStatistics() {
    final total = _cacheHits + _cacheMisses;
    return {
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': total > 0 ? (_cacheHits * 100 ~/ total) : 0,
      'total': total,
    };
  }
  
  /// 첫 번째 날씨 데이터 가져오기 (현재 날씨)
  WidModel? get currentWeather => _weatherList.isNotEmpty ? _weatherList.first : null;
  
  /// 파고 평균 계산
  double get averageWaveHeight {
    if (_weatherList.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final weather in _weatherList) {
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
  
  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
    AppLogger.d('🗑️ Weather cache cleared');
  }
  
  @override
  void dispose() {
    _weatherList.clear();
    _windDirection.clear();
    _windSpeed.clear();
    _windIcon.clear();
    _cache.clear();
    super.dispose();
  }
}
