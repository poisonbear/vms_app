// lib/presentation/providers/vessel_provider.dart

import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 선박 정보 Provider (LRU 캐시 최적화)
class VesselProvider extends BaseProvider {
  late final VesselRepository _vesselRepository;

  //LRU 캐시 (자동 메모리 관리)
  final _cache = MemoryCache();

  List<VesselSearchModel> _vessels = [];

  // 캐시 통계
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // Getters
  List<VesselSearchModel> get vessels => _vessels;
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;

  VesselProvider() {
    _vesselRepository = getIt<VesselRepository>();
  }

  /// 선박 목록 조회 (LRU 캐싱 최적화)
  ///
  /// - 캐시 유효 시간: 5분
  /// - 자동 LRU: 오래된 데이터 자동 제거
  /// - forceRefresh: true 시 캐시 무시하고 서버 호출
  Future<void> getVesselList({
    String? regDt,
    int? mmsi,
    bool forceRefresh = false,
  }) async {
    // 캐시 키 생성
    final cacheKey = _generateCacheKey(regDt, mmsi);

    //강제 새로고침이 아닐 때만 캐시 확인 (로딩 상태 없이)
    if (!forceRefresh) {
      final cachedData = _cache.get<List<VesselSearchModel>>(cacheKey);
      if (cachedData != null) {
        _cacheHits++;
        AppLogger.d('[캐시 HIT] 선박 목록 (hits: $_cacheHits)');
        AppLogger.d('캐시된 선박: ${cachedData.length}개');

        _vessels = cachedData;
        safeNotifyListeners();
        return; // 캐시 히트 시 즉시 리턴
      }
    }

    //캐시 미스 또는 강제 새로고침 - API 호출만 executeAsync로 감싸기
    _cacheMisses++;
    AppLogger.d('[캐시 MISS] 선박 목록 API 호출 (misses: $_cacheMisses)');

    final vessels = await executeAsync<List<VesselSearchModel>>(
      () async {
        return await _vesselRepository.getVesselList(
          regDt: regDt,
          mmsi: mmsi,
        );
      },
      errorMessage: ErrorMessages.vesselListLoadFailed,
      showLoading: true,
      onError: (error) {
        if (error is AuthException) {
          setError('다시 로그인해주세요');
        }
      },
    );

    //응답 처리 (executeAsync 밖에서)
    if (vessels != null) {
      _vessels = vessels;

      // LRU 캐시 저장 (5분, 자동 메모리 관리)
      _cache.put(cacheKey, vessels, AppDurations.minutes5);
      AppLogger.d('[캐시 저장] 선박 ${vessels.length}개 (5분 유효)');

      safeNotifyListeners();
    } else {
      AppLogger.w('[WARNING] API 응답이 null입니다');
      _vessels = [];
      safeNotifyListeners();
    }
  }

  /// 캐시 키 생성
  String _generateCacheKey(String? regDt, int? mmsi) {
    return 'vessel_list_${mmsi ?? "all"}_${regDt ?? "current"}';
  }

  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    AppLogger.d('[CACHE] VesselProvider 캐시 클리어');
  }

  /// 선박 목록 초기화 (메모리만)
  void clearVessels() {
    executeSafe(() {
      _vessels = [];
      safeNotifyListeners();
    });
  }

  /// 특정 MMSI 선박 찾기
  VesselSearchModel? findVesselByMmsi(int mmsi) {
    try {
      return _vessels.firstWhere((vessel) => vessel.mmsi == mmsi);
    } catch (e) {
      return null;
    }
  }

  /// 선박명으로 검색
  List<VesselSearchModel> searchByName(String query) {
    if (query.isEmpty) return _vessels;

    return _vessels.where((vessel) {
      final shipName = vessel.ship_nm?.toLowerCase() ?? '';
      return shipName.contains(query.toLowerCase());
    }).toList();
  }

  /// 선박 개수
  int get vesselCount => _vessels.length;

  /// 선박 목록이 비어있는지 확인
  bool get isEmpty => _vessels.isEmpty;

  /// 선박 목록이 있는지 확인
  bool get isNotEmpty => _vessels.isNotEmpty;

  /// 캐시 통계 가져오기
  Map<String, dynamic> getCacheStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0
        ? (_cacheHits / totalRequests * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'totalRequests': totalRequests,
      'hitRate': '$hitRate%',
      'cachedVessels': _vessels.length,
    };
  }

  /// 캐시 상태 디버그 출력
  void printCacheStats() {
    final stats = getCacheStatistics();
    AppLogger.d('VesselProvider 캐시 통계:');
    AppLogger.d('Hits: ${stats['cacheHits']}, Misses: ${stats['cacheMisses']}');
    AppLogger.d('Hit Rate: ${stats['hitRate']}');
    AppLogger.d('현재 선박: ${stats['cachedVessels']}개');

    // MemoryCache 전체 통계
    _cache.printDebugInfo();
  }

  @override
  void dispose() {
    _vessels.clear();
    clearCache();
    AppLogger.d('VesselProvider disposed');
    super.dispose();
  }
}
