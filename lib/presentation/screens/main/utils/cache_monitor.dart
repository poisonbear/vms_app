import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 캐시 상태 모니터링 유틸리티
class CacheMonitor {
  static final _cache = MemoryCache();

  /// 캐시 상태 로깅
  static void logCacheStatus(String prefix) {
    AppLogger.d('======= 캐시 상태 ($prefix) =======');
    // SimpleCache는 내부 Map 접근이 제한되어 있으므로
    // 실제 캐시 키를 알고 있는 경우에만 체크 가능
    AppLogger.d('캐시 시스템 활성화됨');
    AppLogger.d('================================');
  }

  /// 특정 키의 캐시 존재 여부 확인
  static bool isCached(String key) {
    final data = _cache.get(key);
    return data != null;
  }

  /// 캐시 통계 (실제 구현시 SimpleCache 수정 필요)
  static Map<String, dynamic> getCacheStats() {
    return {
      'system': 'SimpleCache',
      'status': 'active',
      'features': [
        '날씨 정보 캐싱 (10분)',
        '항행경보 캐싱 (30분)',
        '기상정보 리스트 캐싱 (30분)',
        '항행이력 캐싱 (1시간) - NEW!',
      ],
    };
  }
}
