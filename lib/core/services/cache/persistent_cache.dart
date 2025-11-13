// lib/core/services/cache/persistent_cache.dart

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

// ============================================
//  캐시 엔트리 (크기 측정 추가)
// ============================================

class CacheEntry<T> {
  final T data;
  final DateTime expiry;
  final int sizeBytes;

  CacheEntry({
    required this.data,
    required this.expiry,
    int? sizeBytes,
  }) : sizeBytes = sizeBytes ?? _calculateSize(data);

  bool get isExpired => DateTime.now().isAfter(expiry);

  static int _calculateSize(dynamic data) {
    try {
      if (data is String) return data.length;
      if (data is List) return data.length * 8;
      if (data is Map) return data.length * 16;
      return jsonEncode(data).length;
    } catch (e) {
      return 0;
    }
  }
}

// ============================================
//  PersistentCacheService (영구 캐시)
// ============================================

class PersistentCacheService {
  static PersistentCacheService? _instance;
  final Map<String, CacheEntry> _memoryCache = {};
  static const String _persistentPrefix = 'cache_';
  static const String _timestampPrefix = 'cache_time_';

  Timer? _maintenanceTimer;
  DateTime? _lastCleanup;

  //  캐시 유효 시간 (분 단위)
  static const Map<String, int> cacheDurationMinutes = {
    'vessel_list': 5,
    'vessel_route': 10,
    'wid_list': 30,
    'weather_data': 10,
    'ros_list': 30,
    'weather_info': 15,
    'weather_latest': 15,
    'nav_warnings': 60,
    'navigation_warnings': 60,
    'user_info': 120,
    'holiday_info': 1440, // 24시간
  };

  PersistentCacheService._() {
    _startMaintenanceTimer();
  }

  factory PersistentCacheService() {
    _instance ??= PersistentCacheService._();
    return _instance!;
  }

  // ============================================
  // 메모리 캐시 메서드
  // ============================================

  void put(String key, dynamic data, Duration duration) {
    _memoryCache[key] = CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );
    AppLogger.d('Memory cache saved: $key');
  }

  T? get<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  bool has(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _memoryCache.remove(key);
      return false;
    }

    return true;
  }

  void remove(String key) {
    _memoryCache.remove(key);
  }

  void clear() {
    _memoryCache.clear();
    AppLogger.d('Memory cache cleared');
  }

  void cleanExpired() {
    final keysToRemove = <String>[];
    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      AppLogger.d('Cleaned ${keysToRemove.length} expired entries');
    }
  }

  // ============================================
  // 영구 캐시 Static 메서드
  // ============================================

  static Future<void> saveCache(String key, dynamic data) async {
    // 메모리 캐시 저장
    PersistentCacheService().put(
      key,
      data,
      Duration(minutes: _getCacheDuration(key)),
    );

    // 영구 저장
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('$_persistentPrefix$key', jsonData);
      await prefs.setString(
        '$_timestampPrefix$key',
        DateTime.now().toIso8601String(),
      );
      AppLogger.d('Persistent cache saved: $key');
    } catch (e) {
      AppLogger.e('Failed to save persistent cache', e);
    }
  }

  static Future<dynamic> getCache(String key) async {
    // 메모리 캐시 먼저 확인
    final memoryData = PersistentCacheService().get(key);
    if (memoryData != null) {
      AppLogger.d('Cache hit (memory): $key');
      return memoryData;
    }

    // 영구 캐시 확인
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_persistentPrefix$key');
      final timestampString = prefs.getString('$_timestampPrefix$key');

      if (jsonString != null && timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        final duration = Duration(minutes: _getCacheDuration(key));

        // 만료 확인
        if (DateTime.now().difference(timestamp) > duration) {
          await removeCache(key);
          return null;
        }

        final data = jsonDecode(jsonString);

        // 메모리 캐시 복원
        final remainingDuration =
            duration - DateTime.now().difference(timestamp);
        PersistentCacheService().put(key, data, remainingDuration);

        AppLogger.d('Cache hit (persistent): $key');
        return data;
      }
    } catch (e) {
      AppLogger.e('Failed to load persistent cache', e);
    }

    return null;
  }

  static Future<void> removeCache(String key) async {
    PersistentCacheService().remove(key);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_persistentPrefix$key');
      await prefs.remove('$_timestampPrefix$key');
      AppLogger.d('Cache removed: $key');
    } catch (e) {
      AppLogger.e('Failed to remove cache', e);
    }
  }

  static Future<bool> hasCache(String key) async {
    if (PersistentCacheService().has(key)) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_persistentPrefix$key');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isCacheValid(String key) async {
    final data = await getCache(key);
    return data != null;
  }

  static Future<void> clearCache(String pattern) async {
    final instance = PersistentCacheService();
    final keysToRemove = instance._memoryCache.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      instance.remove(key);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) =>
          (key.startsWith(_persistentPrefix) ||
              key.startsWith(_timestampPrefix)) &&
          key.contains(pattern));

      for (final key in keys) {
        await prefs.remove(key);
      }

      AppLogger.d('Cache cleared for pattern: $pattern');
    } catch (e) {
      AppLogger.e('Failed to clear cache', e);
    }
  }

  static Future<void> clearAllCache() async {
    PersistentCacheService().clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) =>
          key.startsWith(_persistentPrefix) ||
          key.startsWith(_timestampPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      AppLogger.d('All cache cleared');
    } catch (e) {
      AppLogger.e('Failed to clear all cache', e);
    }
  }

  static Future<String> getCacheSize() async {
    try {
      int totalSize = 0;

      // 메모리 캐시 크기
      final instance = PersistentCacheService();
      instance._memoryCache.forEach((key, entry) {
        totalSize += entry.sizeBytes;
      });

      // 영구 캐시 크기
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_persistentPrefix)) {
          final data = prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        }
      }

      if (totalSize < 1024) {
        return '${totalSize}B';
      } else if (totalSize < 1024 * 1024) {
        return '${(totalSize / 1024).toStringAsFixed(2)}KB';
      } else {
        return '${(totalSize / 1024 / 1024).toStringAsFixed(2)}MB';
      }
    } catch (e) {
      AppLogger.e('Failed to calculate cache size', e);
      return 'Unknown';
    }
  }

  void _startMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => performMaintenance(),
    );
  }

  void performMaintenance() {
    cleanExpired();
    _lastCleanup = DateTime.now();
    final stats = getStatistics();
    AppLogger.d('Cache maintenance: $stats');
  }

  static int _getCacheDuration(String key) {
    final baseKey = _extractBaseKey(key);
    return cacheDurationMinutes[baseKey] ?? 30;
  }

  static String _extractBaseKey(String key) {
    // 정확한 매칭 먼저 시도
    if (cacheDurationMinutes.containsKey(key)) {
      return key;
    }

    // 접두사 매칭
    for (final baseKey in cacheDurationMinutes.keys) {
      if (key.startsWith(baseKey)) {
        return baseKey;
      }
    }

    // 첫 두 단어로 매칭 시도
    final parts = key.split('_');
    if (parts.length >= 2) {
      final candidate = '${parts[0]}_${parts[1]}';
      if (cacheDurationMinutes.containsKey(candidate)) {
        return candidate;
      }
    }

    return key;
  }

  Map<String, dynamic> getStatistics() {
    int activeCount = 0;
    int expiredCount = 0;
    int totalSize = 0;
    final typeCount = <String, int>{};

    _memoryCache.forEach((key, entry) {
      totalSize += entry.sizeBytes;

      if (entry.isExpired) {
        expiredCount++;
      } else {
        activeCount++;
      }

      final baseKey = _extractBaseKey(key);
      typeCount[baseKey] = (typeCount[baseKey] ?? 0) + 1;
    });

    return {
      'total': _memoryCache.length,
      'active': activeCount,
      'expired': expiredCount,
      'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
      'types': typeCount,
      'lastCleanup': _lastCleanup?.toIso8601String() ?? 'Never',
    };
  }

  void dispose() {
    _maintenanceTimer?.cancel();
    clear();
  }
}

// ============================================
//  CacheManager (간편 API)
// ============================================

class CacheManager {
  CacheManager._();

  static Future<void> saveCache(String key, dynamic data) =>
      PersistentCacheService.saveCache(key, data);

  static Future<dynamic> getCache(String key) =>
      PersistentCacheService.getCache(key);

  static Future<void> removeCache(String key) =>
      PersistentCacheService.removeCache(key);

  static Future<bool> hasCache(String key) =>
      PersistentCacheService.hasCache(key);

  static Future<bool> isCacheValid(String key) =>
      PersistentCacheService.isCacheValid(key);

  static Future<void> clearCache(String pattern) =>
      PersistentCacheService.clearCache(pattern);

  static Future<void> clearAllCache() => PersistentCacheService.clearAllCache();

  static Future<String> getCacheSize() => PersistentCacheService.getCacheSize();
}
