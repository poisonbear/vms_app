import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/logger.dart';

/// API 응답 캐싱 관리자
class CacheManager {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'cache_time_';
  
  // 캐시 유효 시간 (분 단위)
  static const Map<String, int> cacheDuration = {
    'vessel_list': 30,      // 30분
    'weather_info': 10,     // 10분
    'navigation_history': 60, // 1시간
    'terms_list': 1440,     // 24시간
  };

  /// 캐시 저장
  static Future<void> saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      // 데이터와 타임스탬프 저장
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      logger.d('Cache saved: $key');
    } catch (e) {
      logger.e('Cache save error: $e');
    }
  }

  /// 캐시 읽기
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      // 캐시 데이터 확인
      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);
      
      if (cachedData == null || timestamp == null) {
        return null;
      }
      
      // 캐시 유효성 검사
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAge = (cacheDuration[key] ?? 30) * 60 * 1000; // 분을 밀리초로 변환
      
      if (cacheAge > maxAge) {
        logger.d('Cache expired: $key');
        await clearCache(key);
        return null;
      }
      
      logger.d('Cache hit: $key');
      return jsonDecode(cachedData);
    } catch (e) {
      logger.e('Cache read error: $e');
      return null;
    }
  }

  /// 특정 캐시 삭제
  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
    await prefs.remove('$_timestampPrefix$key');
  }

  /// 모든 캐시 삭제
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
    
    logger.d('All cache cleared');
  }

  /// 캐시 크기 확인
  static Future<String> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int totalSize = 0;
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    }
    
    // 바이트를 KB로 변환
    final sizeKB = (totalSize / 1024).toStringAsFixed(2);
    return '${sizeKB}KB';
  }
}
