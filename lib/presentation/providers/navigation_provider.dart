// NavigationProvider 수정 버전 - 캐싱 적용

import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart' as weather_usecase;
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/cache/simple_cache.dart';

class NavigationProvider extends BaseProvider {
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 캐시 매니저 추가
  final _cache = SimpleCache(); // ← 추가

  // 기존 구조 유지 - State variables
  List<dynamic> _rosList = [];
  bool _isInitialized = false;
  List<String> _navigationWarnings = [];

  // Weather data - 기존 변수명 그대로 유지 (public)
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

  // 기존 getters 유지
  List<dynamic> get rosList => _rosList;
  List<dynamic> get RosList => _rosList; // 하위 호환성
  bool get isInitialized => _isInitialized;
  List<String> get navigationWarnings => _navigationWarnings;

  String get combinedNavigationWarnings {
    if (_navigationWarnings.isEmpty) {
      return '금일 항행경보가 없습니다.';
    }
    return _navigationWarnings.join('             ');
  }

  NavigationProvider() {
    _navigationRepository = getIt<NavigationRepository>();
    _getNavigationHistory = getIt<GetNavigationHistory>();
    _getWeatherInfo = getIt<weather_usecase.GetWeatherInfo>();

    // 초기 데이터 로드
    getWeatherInfo();
    getNavigationWarnings();
  }

  // 기존 메서드 유지
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

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
      notifyListeners();
    }
  }

  Future<void> getWeatherInfo() async {
    print('getWeatherInfo 호출됨');
    // ========== 캐싱 로직 추가 시작 ==========
    // 캐시 키 생성 (10분 단위)
    final now = DateTime.now();
    final cacheKey = 'weather_${now.hour}_${now.minute ~/ 10}';

    // 캐시에서 먼저 확인
    final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      print('✅ [캐시 사용] 날씨 정보');
      print('📦 캐시 데이터: $cachedData');
      // 캐시된 데이터 복원
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

      print('🌊 wave: $wave, visibility: $visibility');
      notifyListeners();
      return;
    }

    print('🔄 [API 호출] 날씨 정보');
    // ========== 캐싱 로직 추가 끝 ==========

    final weatherInfo = await executeAsync(
          () => _getWeatherInfo.execute(),
      errorMessage: '기상 정보 로드 중 오류',
      showLoading: false,
    );

    if (weatherInfo != null) {
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

      // ========== 캐시 저장 추가 ==========
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
      print('💾 [캐시 저장] 날씨 정보 (10분간 유효)');
      // ========== 캐시 저장 끝 ==========

      notifyListeners();
    }
  }

  Future<void> getNavigationWarnings() async {
    // ========== 항행경보 캐싱 추가 ==========
    final cacheKey = 'nav_warnings_${DateTime.now().hour}';

    // 캐시 확인
    final cached = _cache.get<List<String>>(cacheKey);
    if (cached != null) {
      print('✅ [캐시 사용] 항행경보');
      _navigationWarnings = cached;
      notifyListeners();
      return;
    }

    print('🔄 [API 호출] 항행경보');
    // ========== 캐싱 로직 끝 ==========

    final warnings = await executeAsync(
          () => _navigationRepository.getNavigationWarnings(),
      errorMessage: '항행경보 로드 중 오류',
      showLoading: false,
    );

    if (warnings != null) {
      _navigationWarnings = warnings;

      // ========== 캐시 저장 ==========
      _cache.put(cacheKey, warnings, const Duration(minutes: 30));
      print('💾 [캐시 저장] 항행경보 (30분간 유효)');
      // ========== 캐시 저장 끝 ==========

      notifyListeners();
    }
  }

  // 기존 Color 반환 메서드들 - 변경 없음
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

  String getFormattedWaveThresholdText(double waveValue) {
    return '파고: ${waveValue.toStringAsFixed(1)}m';
  }

  String getFormattedVisibilityThresholdText(double visibilityValue) {
    if (visibilityValue >= 1000) {
      double visibilityInKm = visibilityValue / 1000;
      if (visibilityInKm % 1 == 0) {
        return '시정: ${visibilityInKm.toStringAsFixed(0)}km';
      } else {
        return '시정: ${visibilityInKm.toStringAsFixed(1)}km';
      }
    } else {
      return '시정: ${visibilityValue.toStringAsFixed(0)}m';
    }
  }

  @override
  void dispose() {
    _rosList.clear();
    _navigationWarnings.clear();
    _isInitialized = false;

    // 캐시 정리 추가
    _cache.clear(); // ← 추가

    wave = 0;
    visibility = 0;
    walm1 = 0.0;
    walm2 = 0.0;
    walm3 = 0.0;
    walm4 = 0.0;
    valm1 = 0.0;
    valm2 = 0.0;
    valm3 = 0.0;
    valm4 = 0.0;

    super.dispose();
  }
}