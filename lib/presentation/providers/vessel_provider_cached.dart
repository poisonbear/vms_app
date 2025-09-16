import 'package:vms_app/presentation/providers/base/base_provider.dart';
import 'package:vms_app/core/cache/cache_manager.dart';
import 'package:vms_app/core/cache/simple_cache.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/core/di/injection.dart';

class VesselProviderCached extends BaseProvider {
  late final VesselRepository _vesselRepository;
  final _memoryCache = SimpleCache();
  
  List<VesselSearchModel> _vessels = [];
  List<VesselSearchModel> get vessels => _vessels;
  
  VesselProviderCached() {
    _vesselRepository = getIt<VesselRepository>();
  }
  
  Future<void> getVesselList({String? regDt, int? mmsi, bool forceRefresh = false}) async {
    final cacheKey = 'vessels_${mmsi ?? "all"}_${regDt ?? "latest"}';
    
    // 1. 메모리 캐시 확인
    if (!forceRefresh) {
      final memoryCached = _memoryCache.get<List<VesselSearchModel>>(cacheKey);
      if (memoryCached != null) {
        AppLogger.d('✅ Vessels from memory cache');
        _vessels = memoryCached;
        notifyListeners();
        return;
      }
    }
    
    // 2. 영구 캐시 확인
    if (!forceRefresh) {
      final persistentCached = await CacheManager.getCache(cacheKey);
      if (persistentCached != null) {
        AppLogger.d('✅ Vessels from persistent cache');
        _vessels = (persistentCached as List)
            .map((json) => VesselSearchModel.fromJson(json))
            .toList();
        
        // 메모리 캐시에도 저장
        _memoryCache.put(cacheKey, _vessels, const Duration(minutes: 10));
        notifyListeners();
        return;
      }
    }
    
    // 3. API 호출 (Repository 사용)
    AppLogger.d('🔄 Loading vessels from API');
    final result = await executeAsync(
      () => _vesselRepository.getVesselList(regDt: regDt, mmsi: mmsi),
      errorMessage: '선박 목록 로드 실패',
    );
    
    if (result != null) {
      _vessels = result;
      
      // 캐시 저장 (toJson 메서드가 있는 경우에만)
      _memoryCache.put(cacheKey, _vessels, const Duration(minutes: 10));
      
      // VesselSearchModel에 toJson이 있다면 사용
      try {
        final dataToCache = _vessels.map((v) => v.toJson()).toList();
        await CacheManager.saveCache(cacheKey, dataToCache);
      } catch (e) {
        AppLogger.d('캐시 저장 스킵 (toJson 없음)');
      }
      
      notifyListeners();
    }
  }
  
  void clearCache() {
    _memoryCache.clear();
    CacheManager.clearCache('vessels');
    AppLogger.d('🗑️ Vessel cache cleared');
  }
  
  void clearVessels() {
    _vessels = [];
    notifyListeners();
  }
  
  @override
  void dispose() {
    _vessels.clear();
    _memoryCache.clear();
    super.dispose();
  }
}
