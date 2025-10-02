// lib/core/services/cache/memory_cache.dart

import 'package:vms_app/core/utils/app_logger.dart';
import 'persistent_cache.dart';

// ============================================
// 🔧 MemoryCache (크기 제한 추가)
// ============================================

class MemoryCache {
  static MemoryCache? _instance;
  final Map<String, CacheEntry> _cache = {};

  // 🔧 신규: 캐시 크기 제한 (기본 10MB)
  static const int maxCacheSizeBytes = 10 * 1024 * 1024;
  int _currentSizeBytes = 0;

  MemoryCache._();

  factory MemoryCache() {
    _instance ??= MemoryCache._();
    return _instance!;
  }

  /// 🔧 개선: 크기 체크 후 저장
  void put<T>(String key, T data, Duration duration) {
    final entry = CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );

    // 기존 항목이 있으면 크기 제거
    if (_cache.containsKey(key)) {
      _currentSizeBytes -= _cache[key]!.sizeBytes;
    }

    // 새 항목 크기 추가
    _currentSizeBytes += entry.sizeBytes;

    // 크기 초과 시 오래된 항목부터 제거
    if (_currentSizeBytes > maxCacheSizeBytes) {
      _evictOldest();
    }

    _cache[key] = entry;
    AppLogger.d('Cache stored: $key (${entry.sizeBytes} bytes)');
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      remove(key);
      return null;
    }

    return entry.data as T?;
  }

  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      remove(key);
      return false;
    }

    return true;
  }

  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
    }
  }

  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
    AppLogger.d('MemoryCache cleared');
  }

  int get size => _cache.length;

  // 🔧 신규: 가장 오래된 항목 제거 (LRU)
  void _evictOldest() {
    if (_cache.isEmpty) return;

    // 만료된 항목 먼저 제거
    cleanExpired();

    // 여전히 크기 초과면 가장 오래된 항목 제거
    while (_currentSizeBytes > maxCacheSizeBytes && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      remove(oldestKey);
      AppLogger.w('Cache eviction: $oldestKey');
    }
  }

  void cleanExpired() {
    final keysToRemove = <String>[];
    _cache.forEach((key, entry) {
      if (entry.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      AppLogger.d('Cleaned ${keysToRemove.length} expired entries');
    }
  }

  // 🔧 신규: 캐시 통계
  Map<String, dynamic> getStats() {
    int activeCount = 0;
    int expiredCount = 0;

    _cache.forEach((key, entry) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        activeCount++;
      }
    });

    return {
      'totalItems': _cache.length,
      'activeItems': activeCount,
      'expiredItems': expiredCount,
      'totalSizeKB': (_currentSizeBytes / 1024).toStringAsFixed(2),
      'maxSizeMB': (maxCacheSizeBytes / 1024 / 1024).toStringAsFixed(2),
      'utilizationPercent':
      ((_currentSizeBytes / maxCacheSizeBytes) * 100).toStringAsFixed(1),
    };
  }
}

// ============================================
// 🔧 CacheMonitor (캐시 상태 모니터링 유틸리티)
// ============================================

class CacheMonitor {
  static final _cache = MemoryCache();

  /// 캐시 상태 로깅
  static void logCacheStatus(String prefix) {
    AppLogger.d('======= 캐시 상태 ($prefix) =======');
    AppLogger.d('캐시 시스템 활성화됨');
    AppLogger.d('캐시 크기: ${_cache.size} 항목');
    AppLogger.d('================================');
  }

  /// 특정 키의 캐시 존재 여부 확인
  static bool isCached(String key) {
    final data = _cache.get(key);
    return data != null;
  }

  /// 캐시 통계
  static Map<String, dynamic> getCacheStats() {
    return {
      'system': 'MemoryCache',
      'status': 'active',
      'size': _cache.size,
      'details': _cache.getStats(),
      'features': [
        '선박 목록 캐싱 (5분)',
        '선박 경로 캐싱 (10분)',
        '날씨 정보 캐싱 (15분)',
        '기상정보 리스트 캐싱 (30분)',
        '항행이력 캐싱 (30분)',
        '항행경보 캐싱 (60분)',
      ],
    };
  }

  /// 상세 캐시 정보 출력 (디버깅용)
  static void printCacheDetails() {
    final stats = _cache.getStats();
    AppLogger.d('📊 MemoryCache Details:');
    AppLogger.d('  - Total Items: ${stats['totalItems']}');
    AppLogger.d('  - Active: ${stats['activeItems']}');
    AppLogger.d('  - Expired: ${stats['expiredItems']}');
    AppLogger.d('  - Size: ${stats['totalSizeKB']} KB');
    AppLogger.d('  - Utilization: ${stats['utilizationPercent']}%');
  }
}