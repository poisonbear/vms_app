// lib/core/services/system/app_initializer.dart

import 'package:flutter/widgets.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import '../cache/cache_service.dart';
import 'timer_service.dart';

/// 앱 초기화 관리자
class AppInitializer {
  AppInitializer._();

  /// 간단한 앱 초기화
  static Future<void> initialize() async {
    try {
      AppLogger.d('Starting app initialization...');

      // 1. Flutter 바인딩 초기화
      WidgetsFlutterBinding.ensureInitialized();

      // 2. 캐시 서비스 초기화
      final cacheService = CacheService();
      cacheService.cleanExpired();

      // 3. 캐시 통계 로깅
      final stats = cacheService.getStatistics();
      AppLogger.d('Cache initialized: $stats');

      AppLogger.d('App initialization completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('App initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// 보안 초기화 (간소화 버전)
  static Future<void> initializeSecurity() async {
    try {
      AppLogger.d('Initializing security...');
      // 보안 관련 초기화 로직을 여기에 추가
      // 예: 인증서 검증, 루트 탐지 등
      AppLogger.d('Security initialization completed');
    } catch (e) {
      AppLogger.e('Security initialization failed: $e');
      // 보안 초기화 실패해도 앱은 계속 실행
    }
  }

  /// 앱 종료시 정리 작업
  static Future<void> cleanup() async {
    AppLogger.d('Starting app cleanup...');

    try {
      // 캐시 정리
      final cacheService = CacheService();
      cacheService.dispose();

      // 타이머 정리
      final timerService = TimerService();
      timerService.dispose();

      AppLogger.d('App cleanup completed');
    } catch (e) {
      AppLogger.e('App cleanup failed: $e');
    }
  }
}