import 'package:flutter/material.dart';
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/cache_service.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart' as weather_usecase;
import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/navigation_model.dart';

/// 항행이력 상태 관리 Provider - 타입 안전성 개선 버전
class NavigationProvider extends BaseProvider {
  // Use Cases
  late final GetNavigationHistory _getNavigationHistory;
  late final weather_usecase.GetWeatherInfo _getWeatherInfo;
  late final NavigationRepository _navigationRepository;

  // 캐시 매니저 - 메모리 캐시
  final SimpleCache _cache = SimpleCache();

  // 🔧 수정: State variables - 명확한 타입 정의
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

  // 🔧 수정: Getters - 타입 안전성 확보
  List<NavigationModel> get rosList => _rosList;
  List<NavigationModel> get RosList => _rosList; // 하위 호환성
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
      _getWeatherInfo = getIt<weather_usecase.GetWeatherInfo>();

      // 초기 데이터 로드
      getWeatherInfo();
      getNavigationWarnings();
    } catch (e) {
      AppLogger.e('NavigationProvider 초기화 실패: $e');
      setError('초기화 중 오류가 발생했습니다.');
    }
  }

  /// 🔧 수정: getRosList - 타입 안전성 확보
  Future<void> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isInitialized = true;

    final cacheKey = 'ros_list_${startDate ?? "none"}_${endDate ?? "none"}_'
        '${mmsi ?? "all"}_${shipName ?? "all"}';

    AppLogger.d('🔍 항행이력 조회 시작 - 캐시키: $cacheKey');

    try {
      // 1️⃣ 메모리 캐시 확인
      final memoryCached = _cache.get<List<NavigationModel>>(cacheKey);
      if (memoryCached != null) {
        AppLogger.d('✅ [메모리 캐시 사용] 항행이력: ${memoryCached.length}건');
        _rosList = memoryCached;
        notifyListeners();
        return;
      }

      // 2️⃣ 영구 저장소 캐시 확인 (안전한 타입 변환 포함)
      try {
        final persistentCached = await CacheManager.getCache(cacheKey);
        if (persistentCached != null) {
          AppLogger.d('✅ [영구 캐시 발견] 항행이력 복원 시도');

          // 🔧 수정: 안전한 타입 변환
          List<NavigationModel> restoredList = [];
          if (persistentCached is List) {
            for (final item in persistentCached) {
              try {
                if (item is Map<String, dynamic>) {
                  // Map에서 NavigationModel로 변환
                  restoredList.add(NavigationModel.fromJson(item));
                } else if (item is NavigationModel) {
                  // 이미 NavigationModel인 경우
                  restoredList.add(item);
                }
              } catch (e) {
                AppLogger.w('영구 캐시 아이템 변환 실패: $e');
              }
            }
          }

          if (restoredList.isNotEmpty) {
            _rosList = restoredList;
            // 메모리 캐시에도 복사
            _cache.put(cacheKey, _rosList, const Duration(hours: 1));
            AppLogger.d('📊 영구 캐시 복원 성공: ${_rosList.length}건');
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        AppLogger.w('영구 캐시 읽기 실패: $e');
      }

      // 3️⃣ API 호출
      AppLogger.d('🔄 [API 호출] 항행이력 리스트');

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

        // 4️⃣ 메모리와 영구 저장소 모두 저장
        _cache.put(cacheKey, result, const Duration(hours: 1));

        try {
          // 🔧 수정: NavigationModel을 Map으로 변환하여 저장
          final dataToCache = result.map((model) => model.toJson()).toList();
          await CacheManager.saveCache(cacheKey, dataToCache);
          AppLogger.d('💾 [캐시 저장] 메모리 + 영구 저장소');
          AppLogger.d('📊 저장된 데이터: ${result.length}건');
        } catch (e) {
          AppLogger.w('영구 캐시 저장 실패: $e');
        }

        notifyListeners();
      } else {
        AppLogger.w('⚠️ API 호출 실패 - 캐시된 데이터 없음');
        _rosList = [];
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('❌ getRosList 실행 중 오류: $e');
      setError('항행 이력을 불러오는 중 오류가 발생했습니다.');
      _rosList = [];
      notifyListeners();
    }
  }

  /// getWeatherInfo - 메모리 + 영구 저장소
  Future<void> getWeatherInfo() async {
    AppLogger.d('getWeatherInfo 호출됨');

    final now = DateTime.now();
    final cacheKey = 'weather_${now.hour}_${now.minute ~/ 10}';

    // 1️⃣ 메모리 캐시 확인
    final memoryCached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (memoryCached != null) {
      AppLogger.d('✅ [메모리 캐시] 날씨 정보');
      _restoreWeatherData(memoryCached);
      notifyListeners();
      return;
    }

    // 2️⃣ 영구 저장소 확인
    try {
      final persistentCached = await CacheManager.getCache('weather_latest');
      if (persistentCached != null) {
        AppLogger.d('✅ [영구 캐시] 날씨 정보');
        _restoreWeatherData(persistentCached as Map<String, dynamic>);

        // 메모리 캐시에 복사
        _cache.put(cacheKey, persistentCached, const Duration(minutes: 10));
        notifyListeners();
        return;
      }
    } catch (e) {
      AppLogger.w('날씨 영구 캐시 읽기 실패: $e');
    }

    // 3️⃣ API 호출
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

      // 4️⃣ 캐시 저장
      _cache.put(cacheKey, dataToCache, const Duration(minutes: 10));

      try {
        await CacheManager.saveCache('weather_latest', dataToCache);
        AppLogger.d('💾 날씨 정보 영구 저장');
      } catch (e) {
        AppLogger.w('날씨 영구 캐시 저장 실패: $e');
      }

      notifyListeners();
    }
  }

  /// getNavigationWarnings - 영구 저장 추가
  Future<void> getNavigationWarnings() async {
    final cacheKey = 'nav_warnings_${DateTime.now().hour}';

    // 1️⃣ 메모리 캐시
    final memoryCached = _cache.get<List<String>>(cacheKey);
    if (memoryCached != null) {
      AppLogger.d('✅ [메모리 캐시] 항행경보');
      _navigationWarnings = memoryCached;
      notifyListeners();
      return;
    }

    // 2️⃣ 영구 저장소
    try {
      final persistentCached = await CacheManager.getCache('nav_warnings_latest');
      if (persistentCached != null) {
        AppLogger.d('✅ [영구 캐시] 항행경보');
        _navigationWarnings = List<String>.from(persistentCached);
        _cache.put(cacheKey, _navigationWarnings, const Duration(minutes: 30));
        notifyListeners();
        return;
      }
    } catch (e) {
      AppLogger.w('항행경보 영구 캐시 읽기 실패: $e');
    }

    // 3️⃣ API 호출
    AppLogger.d('🔄 [API 호출] 항행경보');

    final warnings = await executeAsync(
          () => _navigationRepository.getNavigationWarnings(),
      errorMessage: '항행경보 로드 중 오류',
      showLoading: false,
    );

    if (warnings != null) {
      _navigationWarnings = warnings;

      // 4️⃣ 캐시 저장
      _cache.put(cacheKey, warnings, const Duration(minutes: 30));

      try {
        await CacheManager.saveCache('nav_warnings_latest', warnings);
        AppLogger.d('💾 항행경보 영구 저장');
      } catch (e) {
        AppLogger.w('항행경보 영구 캐시 저장 실패: $e');
      }

      notifyListeners();
    }
  }

  /// Helper 메소드 - 날씨 데이터 복원
  void _restoreWeatherData(Map<String, dynamic> data) {
    wave = (data['wave'] as num?)?.toDouble() ?? 0.0;
    visibility = (data['visibility'] as num?)?.toDouble() ?? 0.0;
    walm1 = (data['walm1'] as num?)?.toDouble() ?? 0.0;
    walm2 = (data['walm2'] as num?)?.toDouble() ?? 0.0;
    walm3 = (data['walm3'] as num?)?.toDouble() ?? 0.0;
    walm4 = (data['walm4'] as num?)?.toDouble() ?? 0.0;
    valm1 = (data['valm1'] as num?)?.toDouble() ?? 0.0;
    valm2 = (data['valm2'] as num?)?.toDouble() ?? 0.0;
    valm3 = (data['valm3'] as num?)?.toDouble() ?? 0.0;
    valm4 = (data['valm4'] as num?)?.toDouble() ?? 0.0;

    AppLogger.d('🌊 wave: $wave, visibility: $visibility');
  }

  // ========== 날씨 관련 UI 메소드 ==========

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
  }

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

  void debugPrintState() {
    AppLogger.d('=== NavigationProvider State ===');
    AppLogger.d('isInitialized: $_isInitialized');
    AppLogger.d('rosList count: ${_rosList.length}');
    AppLogger.d('rosList type: ${_rosList.runtimeType}');
    if (_rosList.isNotEmpty) {
      AppLogger.d('first item type: ${_rosList.first.runtimeType}');
      AppLogger.d('first item mmsi: ${_rosList.first.mmsi}');
    }
    AppLogger.d('isLoading: $isLoading');
    AppLogger.d('hasError: $hasError');
    AppLogger.d('wave: $wave, visibility: $visibility');
    AppLogger.d('warnings: ${_navigationWarnings.length}');
    AppLogger.d('cache size: ${_cache.size}');
    AppLogger.d('================================');
  }

  @override
  void dispose() {
    clearCache();
    _rosList.clear();
    _navigationWarnings.clear();
    AppLogger.d('NavigationProvider disposed');
    super.dispose();
  }
}