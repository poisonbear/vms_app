// lib/core/services/system/app_initializer.dart

import 'package:flutter/widgets.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/services/services.dart';

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
      final persistentCacheService = PersistentCacheService();
      persistentCacheService.cleanExpired();

      // 3. 캐시 통계 로깅
      final stats = persistentCacheService.getStatistics();
      AppLogger.d('Cache initialized: $stats');

      AppLogger.d('App initialization completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('App initialization failed', e, stackTrace);
      rethrow;
    }
  }

  ///보안 초기화 (마이그레이션 추가)
  static Future<void> initializeSecurity() async {
    try {
      AppLogger.i('========== 보안 초기화 시작 ==========');

      final secureStorage = SecureStorageService();
      final migrationSuccess =
          await secureStorage.migrateFromSharedPreferences();

      if (migrationSuccess) {
        AppLogger.i('보안 스토리지 마이그레이션 완료');
      } else {
        AppLogger.w('보안 스토리지 마이그레이션 실패 (기존 데이터 없거나 오류)');
      }

      // 2. 추가 보안 초기화 로직을 여기에 추가 가능
      // 예: 인증서 검증, 루트 탐지, 보안 정책 확인 등

      AppLogger.i('========== 보안 초기화 완료 ==========');
    } catch (e, stackTrace) {
      AppLogger.e('Security initialization failed', e, stackTrace);
      // 보안 초기화 실패해도 앱은 계속 실행
      // 중요: 프로덕션에서는 보안 초기화 실패 시 추가 처리 고려
    }
  }

  /// 앱 종료시 정리 작업
  static Future<void> cleanup() async {
    AppLogger.d('Starting app cleanup...');

    try {
      // 캐시 정리
      final persistentCacheService = PersistentCacheService();
      persistentCacheService.dispose();

      // 타이머 정리
      final timerService = TimerService();
      timerService.dispose();

      AppLogger.d('App cleanup completed');
    } catch (e) {
      AppLogger.e('App cleanup failed: $e');
    }
  }
}
