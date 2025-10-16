// lib/presentation/providers/route_provider.dart
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';
import 'package:vms_app/core/constants/constants.dart';

class RouteProvider extends BaseProvider {
  late final VesselRepository _vesselRepository;

  // 캐시 매니저
  final _cache = MemoryCache();

  List<PastRouteSearchModel> _pastRouteList = [];
  List<PredRouteSearchModel> _predRouteList = [];
  bool _isNavigationHistoryMode = false;

  // ✅ 모든 Getters (호환성 100%)
  List<PastRouteSearchModel> get pastRouteList => _pastRouteList;
  List<PredRouteSearchModel> get predRouteList => _predRouteList;

  // ✅ 추가: 다른 파일에서 사용하는 이름
  List<PastRouteSearchModel> get pastRoutes => _pastRouteList;
  List<PredRouteSearchModel> get predRoutes => _predRouteList;

  bool get isNavigationHistoryMode => _isNavigationHistoryMode;

  RouteProvider() {
    _vesselRepository = getIt<VesselRepository>();
  }

  // ✅ 메서드명: getVesselRoute (기존 코드 호환)
  Future<void> getVesselRoute({String? regDt, int? mmsi}) async {
    try {
      AppLogger.d('==========================================');
      AppLogger.d('[DEBUG] getVesselRoute 호출');
      AppLogger.d('[DEBUG] mmsi: $mmsi');
      AppLogger.d('[DEBUG] regDt: $regDt');
      AppLogger.d('==========================================');

      // ========== 캐싱 로직 활성화 ==========
      final cacheKey = 'vessel_route_${mmsi ?? "none"}_${regDt ?? "current"}';

      // 캐시에서 먼저 확인
      final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        AppLogger.d('✅ [캐시 사용] 항행이력 지도 데이터');

        try {
          // 캐시된 데이터 복원
          _pastRouteList = (cachedData['past'] as List<dynamic>?)
                  ?.map((item) => PastRouteSearchModel(
                        regDt: item['regDt'],
                        mmsi: item['mmsi'],
                        lntd: item['lntd'],
                        lttd: item['lttd'],
                        spd: item['spd'],
                        cog: item['cog'],
                      ))
                  .toList() ??
              [];

          _predRouteList = (cachedData['pred'] as List<dynamic>?)
                  ?.map((item) => PredRouteSearchModel(
                        pdcthh: item['pdcthh'],
                        lntd: item['lntd'],
                        lttd: item['lttd'],
                        spd: item['spd'],
                      ))
                  .toList() ??
              [];

          AppLogger.d(
              '📊 캐시 데이터 복원 - past: ${_pastRouteList.length}, pred: ${_predRouteList.length}');
          safeNotifyListeners();
          return;
        } catch (e) {
          AppLogger.w('⚠️ 캐시 복원 실패, API 호출로 진행: $e');
        }
      }
      // ========== 캐싱 로직 끝 ==========

      AppLogger.d('[API] 호출 시작...');

      final response = await executeAsync(() async {
        return await _vesselRepository.getVesselRoute(
          regDt: regDt,
          mmsi: mmsi,
        );
      }, errorMessage: '항로 조회 중 오류 발생');

      if (response != null) {
        _pastRouteList = response.past;
        _predRouteList = response.pred;

        AppLogger.d('==========================================');
        AppLogger.i('[SUCCESS] API 응답 수신 완료!');
        AppLogger.i('[SUCCESS] past 데이터: ${response.past.length}건');
        AppLogger.i('[SUCCESS] pred 데이터: ${response.pred.length}건');

        // 첫 번째 데이터 샘플 출력
        if (response.past.isNotEmpty) {
          final first = response.past.first;
          AppLogger.d('[SAMPLE] 첫 번째 past 데이터:');
          AppLogger.d('  - mmsi: ${first.mmsi}');
          AppLogger.d('  - 위도: ${first.lttd}');
          AppLogger.d('  - 경도: ${first.lntd}');
        }
        AppLogger.d('==========================================');

        // ========== 응답 캐싱 ==========
        try {
          // 데이터를 캐시에 저장
          final cacheData = {
            'past': _pastRouteList
                .map((route) => {
                      'regDt': route.regDt,
                      'mmsi': route.mmsi,
                      'lntd': route.lntd,
                      'lttd': route.lttd,
                      'spd': route.spd,
                      'cog': route.cog,
                    })
                .toList(),
            'pred': _predRouteList
                .map((route) => {
                      'pdcthh': route.pdcthh,
                      'lntd': route.lntd,
                      'lttd': route.lttd,
                      'spd': route.spd,
                    })
                .toList(),
          };

          _cache.put(cacheKey, cacheData, AppDurations.hours2);
          AppLogger.d('💾 [캐시 저장] 항행이력 지도 데이터 (2시간 유효)');
        } catch (e) {
          AppLogger.w('⚠️ 캐시 저장 실패 (무시하고 계속): $e');
        }
        // ========== 캐싱 완료 ==========

        safeNotifyListeners();
      } else {
        AppLogger.d('==========================================');
        AppLogger.w('[WARNING] API 응답이 null입니다');
        AppLogger.w('[WARNING] 데이터를 가져올 수 없습니다');
        AppLogger.d('==========================================');

        // 빈 리스트로 초기화
        _pastRouteList = [];
        _predRouteList = [];
        safeNotifyListeners();
      }
    } catch (e) {
      AppLogger.d('==========================================');
      AppLogger.e('[EXCEPTION] getVesselRoute 예외 발생!');
      AppLogger.e('[EXCEPTION] 에러 타입: ${e.runtimeType}');
      AppLogger.e('[EXCEPTION] 에러 메시지: $e');
      AppLogger.d('==========================================');

      // 에러 발생시 빈 리스트로 설정
      _pastRouteList = [];
      _predRouteList = [];

      setError('항행이력 조회 실패: $e');
      safeNotifyListeners();
    }
  }

  void setNavigationHistoryMode(bool value) {
    _isNavigationHistoryMode = value;
    safeNotifyListeners();
  }

  void clearRoutes() {
    _pastRouteList = [];
    _predRouteList = [];
    _isNavigationHistoryMode = false;
    clearError();
    safeNotifyListeners();
  }

  void clearCache() {
    _cache.clear();
    AppLogger.d('[CACHE] 캐시가 클리어되었습니다');
  }

  void setPastRoutes(List<PastRouteSearchModel> routes) {
    _pastRouteList = routes;
    safeNotifyListeners();
  }

  void setPredRoutes(List<PredRouteSearchModel> routes) {
    _predRouteList = routes;
    safeNotifyListeners();
  }

  bool get hasData => _pastRouteList.isNotEmpty || _predRouteList.isNotEmpty;

  void reset() {
    _pastRouteList = [];
    _predRouteList = [];
    _isNavigationHistoryMode = false;
    clearError();
    setLoading(false);
    safeNotifyListeners();
  }

  @override
  void dispose() {
    clearRoutes();
    clearCache();
    super.dispose();
  }
}
