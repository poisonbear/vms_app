// lib/presentation/providers/vessel_provider.dart

import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 선박 정보 Provider (SimpleCache 추가)
class VesselProvider extends BaseProvider {
  late final VesselRepository _vesselRepository;

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

  /// 선박 목록 조회 (캐싱 포함)
  ///
  /// - 캐시 유효 시간: 5분
  /// - forceRefresh: true 시 캐시 무시하고 서버 호출
  Future<void> getVesselList({
    String? regDt,
    int? mmsi,
    bool forceRefresh = false,
  }) async {
    await executeAsync<void>(
          () async {
        // 캐시 키 생성
        final cacheKey = _generateCacheKey(regDt, mmsi);

        // 강제 새로고침이 아닐 때만 캐시 확인
        if (!forceRefresh) {
          final cachedData = _cache.get<List<VesselSearchModel>>(cacheKey);
          if (cachedData != null) {
            _cacheHits++;
            AppLogger.d('✅ [캐시 사용] 선박 목록 (hits: $_cacheHits)');
            AppLogger.d('📊 캐시된 선박 수: ${cachedData.length}');

            _vessels = cachedData;
            safeNotifyListeners();
            return;
          }
        }

        // 캐시 미스 또는 강제 새로고침
        _cacheMisses++;
        AppLogger.d('🔄 [API 호출] 선박 목록 (misses: $_cacheMisses)');

        _vessels = await _vesselRepository.getVesselList(
          regDt: regDt,
          mmsi: mmsi,
        );

        // 캐시 저장 (5분)
        _cache.put(cacheKey, _vessels, const Duration(minutes: 5));
        AppLogger.d('💾 [캐시 저장] 선박 목록 (5분 유효, ${_vessels.length}개)');

        safeNotifyListeners();
      },
      errorMessage: '선박 목록을 불러오는 중 오류가 발생했습니다',
      onError: (error) {
        if (error is AuthException) {
          setError('다시 로그인해주세요');
        }
      },
    );
  }

  /// 캐시 클리어
  ///
  /// 선박 관련 캐시를 모두 삭제합니다.
  void clearCache() {
    _cache.clear();
    AppLogger.d('VesselProvider cache cleared');
  }

  /// 선박 목록 초기화 (메모리만)
  ///
  /// 캐시는 유지하고 메모리의 선박 목록만 비웁니다.
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
      AppLogger.w('MMSI $mmsi 선박을 찾을 수 없음');
      return null;
    }
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

  /// 캐시 키 생성
  String _generateCacheKey(String? regDt, int? mmsi) {
    return 'vessel_list_${mmsi ?? "all"}_${regDt ?? "current"}';
  }

  @override
  void dispose() {
    _vessels.clear();
    _cache.clear();
    AppLogger.d('VesselProvider disposed');
    super.dispose();
  }
}