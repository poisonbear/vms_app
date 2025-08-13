import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';
import 'exceptions.dart';

/// 에러 로깅 관리 클래스
/// 로컬 로그와 원격 크래시 리포팅을 통합 관리
class ErrorLogger {
  ErrorLogger._();

  /// 에러 로깅
  /// [error] - 발생한 에러
  /// [stackTrace] - 스택 트레이스
  /// [fatal] - 치명적 에러 여부 (기본값: false)
  /// [context] - 추가 컨텍스트 정보
  static Future<void> logError(
      dynamic error, {
        StackTrace? stackTrace,
        bool fatal = false,
        Map<String, dynamic>? context,
      }) async {
    try {
      // 로컬 로그
      logger.e('Error logged', error, stackTrace);

      // Firebase Crashlytics에 에러 전송
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        information: context?.entries.map((e) =>
            DiagnosticsProperty(e.key, e.value)
        ).toList() ?? [],
      );

      // 커스텀 키 설정 (컨텍스트 정보가 있는 경우)
      if (context != null) {
        for (final entry in context.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            entry.key,
            entry.value?.toString() ?? 'null',
          );
        }
      }

    } catch (e) {
      // 로깅 자체에서 에러가 발생한 경우 로컬 로그만 남김
      logger.e('Failed to log error to Crashlytics', e);
    }
  }

  /// 사용자 정보 설정 (크래시 리포트에 포함)
  /// [userId] - 사용자 ID
  /// [email] - 사용자 이메일
  /// [customAttributes] - 추가 사용자 속성
  static Future<void> setUserInfo({
    String? userId,
    String? email,
    Map<String, String>? customAttributes,
  }) async {
    try {
      if (userId != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }

      if (customAttributes != null) {
        for (final entry in customAttributes.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            entry.key,
            entry.value,
          );
        }
      }
    } catch (e) {
      logger.e('Failed to set user info for Crashlytics', e);
    }
  }

  /// 커스텀 로그 메시지 기록
  /// [message] - 로그 메시지
  /// [level] - 로그 레벨
  static Future<void> logMessage(
      String message, {
        String level = 'INFO',
      }) async {
    try {
      await FirebaseCrashlytics.instance.log('[$level] $message');
      logger.i(message);
    } catch (e) {
      logger.e('Failed to log message to Crashlytics', e);
    }
  }

  /// 앱 성능 지표 로깅
  /// [metricName] - 지표 이름
  /// [value] - 지표 값
  /// [attributes] - 추가 속성
  static Future<void> logPerformanceMetric(
      String metricName,
      num value, {
        Map<String, String>? attributes,
      }) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey(metricName, value);

      if (attributes != null) {
        for (final entry in attributes.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            '${metricName}_${entry.key}',
            entry.value,
          );
        }
      }

      logger.i('Performance metric: $metricName = $value');
    } catch (e) {
      logger.e('Failed to log performance metric', e);
    }
  }
}