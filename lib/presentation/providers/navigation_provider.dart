// NavigationProvider 수정 버전 - getRosList 캐싱 추가

import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart' as weather_usecase;
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/cache/simple_cache.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class NavigationProvider extends BaseProvider {
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 캐시 매니저 추가
  final _cache = SimpleCache();

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

  // getRosList 메서드 - 캐싱 추가
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

    // ========== 캐싱 로직 추가 시작 ==========
    // 캐시 키 생성 (파라미터 조합)
    final cacheKey = 'ros_list_${startDate ?? "none"}_${endDate ?? "none"}_${mmsi ?? "all"}_${shipName ?? "all"}';
    
    // 캐시에서 먼저 확인
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
    // ========== 캐싱 로직 추가 끝 ==========

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
      
      // ========== 캐시 저장 추가 ==========
      _cache.put(cacheKey, result, const Duration(hours: 1));
      AppLogger.d('💾 [캐시 저장] 항행이력 리스트 (1시간 유효)');
      AppLogger.d('📊 저장된 데이터: ${result.length}건');
      // ========== 캐시 저장 끝 ==========
      
      notifyListeners();
    } else {
      AppLogger.w('⚠️ [API 실패] 결과가 null');
      _rosList = [];
      notifyListeners();
    }
  }

  Future<void> getWeatherInfo() async {
    AppLogger.d('getWeatherInfo 호출됨');
    // 캐시 키 생성 (10분 단위)
    final now = DateTime.now();
    final cacheKey = 'weather_${now.hour}_${now.minute ~/ 10}';

    // 캐시에서 먼저 확인
    final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      AppLogger.d('✅ [캐시 사용] 날씨 정보');
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

      AppLogger.d('🌊 wave: $wave, visibility: $visibility');
      notifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 날씨 정보');

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

      // 캐시 저장
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

  Future<void> getNavigationWarnings() async {
    // 항행경보 캐싱
    final cacheKey = 'nav_warnings_${DateTime.now().hour}';

    // 캐시 확인
    final cached = _cache.get<List<String>>(cacheKey);
    if (cached != null) {
      AppLogger.d('✅ [캐시 사용] 항행경보');
      _navigationWarnings = cached;
      notifyListeners();
      return;
    }

    AppLogger.d('🔄 [API 호출] 항행경보');

    final warnings = await executeAsync(
      () => _navigationRepository.getNavigationWarnings(),
      errorMessage: '항행경보 로드 중 오류',
      showLoading: false,
    );

    if (warnings != null) {
      _navigationWarnings = warnings;

      // 캐시 저장
      _cache.put(cacheKey, warnings, const Duration(minutes: 30));
      AppLogger.d('💾 [캐시 저장] 항행경보 (30분간 유효)');

      notifyListeners();
    }
  }

  // 캐시 클리어 메서드 추가
  void clearCache() {
    _cache.clear();
    AppLogger.d('🗑️ 모든 캐시 클리어');
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
  }  // ← 이 중괄호가 있는지 확인

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
  }  // ← 이 중괄호가 있는지 확인

}  // ← 클래스 끝 중괄호
