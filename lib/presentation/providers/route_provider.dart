// lib/presentation/providers/route_provider.dart
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

class RouteProvider extends BaseProvider {
  late final VesselRepository _vesselRepository;

  // 캐시 매니저
  final _cache = MemoryCache();

  List<PastRouteSearchModel> _pastRouteList = [];
  List<PredRouteSearchModel> _predRouteList = [];
  bool _isNavigationHistoryMode = false;

  //모든 Getters (호환성 100%)
  List<PastRouteSearchModel> get pastRouteList => _pastRouteList;
  List<PredRouteSearchModel> get predRouteList => _predRouteList;
  List<PastRouteSearchModel> get pastRoutes => _pastRouteList;
  List<PredRouteSearchModel> get predRoutes => _predRouteList;
  bool get isNavigationHistoryMode => _isNavigationHistoryMode;

  RouteProvider() {
    _vesselRepository = getIt<VesselRepository>();
  }

  Future<void> getVesselRoute({String? regDt, int? mmsi}) async {
    AppLogger.d('==========================================');
    AppLogger.d('[DEBUG] getVesselRoute 호출');
    AppLogger.d('[DEBUG] mmsi: $mmsi');
    AppLogger.d('[DEBUG] regDt: $regDt');
    AppLogger.d('==========================================');

    // 캐시 체크는 executeAsync 밖에서 (로딩 상태 없이)
    final cacheKey = 'vessel_route_${mmsi ?? "none"}_${regDt ?? "current"}';
    final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);

    if (cachedData != null) {
      AppLogger.d('[캐시 사용] 항행이력 지도 데이터');
      _restoreFromCache(cachedData);
      safeNotifyListeners();
      return; // 캐시 히트 시 로딩 없이 즉시 리턴
    }

    //  API 호출만 executeAsync로 감싸기
    AppLogger.d('[API] 호출 시작...');

    final response = await executeAsync<VesselRouteResponse>(
      () async {
        return await _vesselRepository.getVesselRoute(
          regDt: regDt,
          mmsi: mmsi,
        );
      },
      errorMessage: ErrorMessages.navigationLoadFailed,
      showLoading: true,
    );

    // 응답 처리 (executeAsync 밖에서)
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

      // 캐시 저장
      _saveToCache(cacheKey);
      safeNotifyListeners();
    } else {
      AppLogger.w('[WARNING] API 응답이 null입니다');
      _pastRouteList = [];
      _predRouteList = [];
      safeNotifyListeners();
    }
  }

  /// 캐시에서 데이터 복원
  void _restoreFromCache(Map<String, dynamic> cachedData) {
    try {
      _pastRouteList = (cachedData['past'] as List<dynamic>?)
              ?.map((item) => PastRouteSearchModel(
                    regDt: item['regDt'],
                    mmsi: item['mmsi'],
                    lntd: item['lntd'],
                    lttd: item['lttd'],
                    sog: item['sog'],
                    cog: item['cog'],
                  ))
              .toList() ??
          [];

      _predRouteList = (cachedData['pred'] as List<dynamic>?)
              ?.map((item) => PredRouteSearchModel(
                    pdcthh: item['pdcthh'],
                    lntd: item['lntd'],
                    lttd: item['lttd'],
                    sog: item['sog'],
                  ))
              .toList() ??
          [];

      AppLogger.d(
          '캐시 데이터 복원 - past: ${_pastRouteList.length}, pred: ${_predRouteList.length}');
    } catch (e) {
      AppLogger.w('캐시 복원 실패: $e');
      _pastRouteList = [];
      _predRouteList = [];
    }
  }

  /// 캐시에 데이터 저장
  void _saveToCache(String cacheKey) {
    try {
      final cacheData = {
        'past': _pastRouteList
            .map((route) => {
                  'regDt': route.regDt,
                  'mmsi': route.mmsi,
                  'lntd': route.lntd,
                  'lttd': route.lttd,
                  'sog': route.sog,
                  'cog': route.cog,
                })
            .toList(),
        'pred': _predRouteList
            .map((route) => {
                  'pdcthh': route.pdcthh,
                  'lntd': route.lntd,
                  'lttd': route.lttd,
                  'sog': route.sog,
                })
            .toList(),
      };
      _cache.put(cacheKey, cacheData, AppDurations.hours2);
      AppLogger.d('[캐시 저장] 항행이력 지도 데이터 (2시간 유효)');
    } catch (e) {
      AppLogger.w('캐시 저장 실패 (무시하고 계속): $e');
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
