// lib/core/services/cache/memory_cache.dart

import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'persistent_cache.dart';

class MemoryCache {
  static MemoryCache? _instance;
  final Map<String, CacheEntry> _cache = {};

  //LRU 추적: 접근 순서 저장
  final List<String> _accessOrder = [];

  //캐시 크기 제한
  static const int maxCacheSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxCacheItems = 100; // 최대 항목 수
  int _currentSizeBytes = 0;

  // 통계
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  MemoryCache._();

  factory MemoryCache() {
    _instance ??= MemoryCache._();
    return _instance!;
  }

  /// 캐시에 데이터 저장 (LRU 적용)
  void put<T>(String key, T data, Duration duration) {
    final entry = CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );

    // 기존 항목이 있으면 크기 제거 및 접근 순서 업데이트
    if (_cache.containsKey(key)) {
      _currentSizeBytes -= _cache[key]!.sizeBytes;
      _accessOrder.remove(key);
    }

    _currentSizeBytes += entry.sizeBytes;

    //크기 또는 개수 초과 시 LRU 적용하여 제거
    while (_shouldEvict()) {
      _evictLRU();
    }

    // 캐시에 저장
    _cache[key] = entry;
    _accessOrder.add(key);

    AppLogger.d(
        'Cache stored: $key (${entry.sizeBytes} bytes, ${_cache.length} items)');
  }

  /// 캐시에서 데이터 가져오기 (LRU 업데이트)
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    // 만료 체크
    if (entry.isExpired) {
      remove(key);
      _misses++;
      return null;
    }

    //LRU: 접근 순서 업데이트
    _accessOrder.remove(key);
    _accessOrder.add(key);

    _hits++;
    return entry.data as T?;
  }

  /// 캐시에 키가 있는지 확인
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      remove(key);
      return false;
    }

    return true;
  }

  /// 캐시에서 제거
  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      _accessOrder.remove(key);
    }
  }

  /// 캐시 전체 삭제
  void clear() {
    _cache.clear();
    _accessOrder.clear();
    _currentSizeBytes = 0;
    AppLogger.i('MemoryCache cleared');
  }

  // ============================================
  // LRU 관리 메서드
  // ============================================

  /// 제거가 필요한지 체크
  bool _shouldEvict() {
    return _cache.length >= maxCacheItems ||
        _currentSizeBytes > maxCacheSizeBytes;
  }

  /// LRU 알고리즘: 가장 오래 사용되지 않은 항목 제거
  void _evictLRU() {
    if (_accessOrder.isEmpty) return;

    // 1순위: 만료된 항목 제거
    final expiredKeys = <String>[];
    for (final key in _accessOrder) {
      final entry = _cache[key];
      if (entry != null && entry.isExpired) {
        expiredKeys.add(key);
      }
    }

    if (expiredKeys.isNotEmpty) {
      for (final key in expiredKeys) {
        remove(key);
        _evictions++;
      }
      AppLogger.d('Evicted ${expiredKeys.length} expired items');
      return;
    }

    // 2순위: 가장 오래 사용되지 않은 항목 제거
    if (_accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.first;
      final entry = _cache[oldestKey];
      remove(oldestKey);
      _evictions++;

      AppLogger.w('LRU eviction: $oldestKey (${entry?.sizeBytes ?? 0} bytes)');
    }
  }

  /// 만료된 항목 정리
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

  // ============================================
  // 통계 및 모니터링
  // ============================================

  /// 캐시 통계
  Map<String, dynamic> getStatistics() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0
        ? (_hits / totalRequests * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'items': _cache.length,
      'maxItems': maxCacheItems,
      'sizeKB': (_currentSizeBytes / 1024).toStringAsFixed(2),
      'maxSizeKB': (maxCacheSizeBytes / 1024).toStringAsFixed(2),
      'hits': _hits,
      'misses': _misses,
      'hitRate': '$hitRate%',
      'evictions': _evictions,
      'oldestKey': _accessOrder.isNotEmpty ? _accessOrder.first : null,
      'newestKey': _accessOrder.isNotEmpty ? _accessOrder.last : null,
    };
  }

  /// 통계 초기화
  void resetStatistics() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    final stats = getStatistics();
    AppLogger.d('MemoryCache Statistics:');
    AppLogger.d('Items: ${stats['items']}/${stats['maxItems']}');
    AppLogger.d('Size: ${stats['sizeKB']}KB / ${stats['maxSizeKB']}KB');
    AppLogger.d('Hit Rate: ${stats['hitRate']}');
    AppLogger.d('Hits: ${stats['hits']}, Misses: ${stats['misses']}');
    AppLogger.d('Evictions: ${stats['evictions']}');

    if (_accessOrder.isNotEmpty) {
      AppLogger.d('Oldest: ${stats['oldestKey']}');
      AppLogger.d('Newest: ${stats['newestKey']}');
    }
  }

  // ============================================
  // Getters
  // ============================================

  int get size => _cache.length;
  int get sizeBytes => _currentSizeBytes;
  double get hitRate => _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0;

  /// 캐시 사용률 (%)
  double get usagePercent => (_cache.length / maxCacheItems * 100);

  /// 메모리 사용률 (%)
  double get memoryUsagePercent =>
      (_currentSizeBytes / maxCacheSizeBytes * 100);
}

// ============================================
// 사용 예시
// ============================================
/*
void main() {
  final cache = MemoryCache();

  // 데이터 저장
  cache.put('user_123', {'name': 'John'}, Duration(minutes: 5));

  // 데이터 가져오기
  final user = cache.get<Map>('user_123');
  print(user); // {name: John}

  // 통계 확인
  cache.printDebugInfo();
  // MemoryCache Statistics:
  //   Items: 1/100
  //   Size: 0.02KB / 10240.00KB
  //   Hit Rate: 100.0%
  //   Hits: 1, Misses: 0

  // 많은 데이터 추가 (LRU 테스트)
  for (int i = 0; i < 150; i++) {
    cache.put('item_$i', 'data_$i', Duration(minutes: 10));
  }

  cache.printDebugInfo();
  // Items: 100/100 (오래된 50개 자동 제거됨)

  // 만료된 항목 정리
  cache.cleanExpired();

  // 캐시 비우기
  cache.clear();
}
*/
