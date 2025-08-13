import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
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
      // 로컬 로그 (named parameters 사용)
      logger.e('Error logged', error: error, stackTrace: stackTrace);

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
      logger.e('Failed to log error to Crashlytics', error: e);
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
      logger.e('Failed to set user info for Crashlytics', error: e);
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
      logger.e('Failed to log message to Crashlytics', error: e);
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
      logger.e('Failed to log performance metric', error: e);
    }
  }

  /// 네트워크 요청 로깅
  /// [method] - HTTP 메서드
  /// [url] - 요청 URL
  /// [statusCode] - 응답 상태 코드
  /// [responseTime] - 응답 시간 (밀리초)
  /// [errorMessage] - 에러 메시지 (있는 경우)
  static Future<void> logNetworkRequest({
    required String method,
    required String url,
    int? statusCode,
    int? responseTime,
    String? errorMessage,
  }) async {
    try {
      final logData = {
        'network_method': method,
        'network_url': url,
        if (statusCode != null) 'network_status_code': statusCode,
        if (responseTime != null) 'network_response_time': responseTime,
        if (errorMessage != null) 'network_error': errorMessage,
      };

      // Crashlytics에 네트워크 정보 기록
      for (final entry in logData.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(
          entry.key,
          entry.value.toString(),
        );
      }

      // 로컬 로그
      if (statusCode != null && statusCode >= 400) {
        logger.w('Network error: $method $url [$statusCode]${errorMessage != null ? ' - $errorMessage' : ''}');
      } else {
        logger.d('Network request: $method $url${statusCode != null ? ' [$statusCode]' : ''}${responseTime != null ? ' (${responseTime}ms)' : ''}');
      }

    } catch (e) {
      logger.e('Failed to log network request', error: e);
    }
  }

  /// 사용자 액션 로깅
  /// [action] - 사용자 액션
  /// [screen] - 현재 화면
  /// [properties] - 추가 속성
  static Future<void> logUserAction({
    required String action,
    String? screen,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final logData = {
        'user_action': action,
        if (screen != null) 'user_screen': screen,
        'user_timestamp': DateTime.now().toIso8601String(),
      };

      // properties 추가
      if (properties != null) {
        for (final entry in properties.entries) {
          logData['user_${entry.key}'] = entry.value.toString();
        }
      }

      // Crashlytics에 사용자 액션 기록
      for (final entry in logData.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(
          entry.key,
          entry.value.toString(),
        );
      }

      // 로컬 로그
      logger.i('User action: $action${screen != null ? ' on $screen' : ''}');

    } catch (e) {
      logger.e('Failed to log user action', error: e);
    }
  }

  /// 비즈니스 이벤트 로깅
  /// [event] - 이벤트 이름
  /// [category] - 이벤트 카테고리
  /// [properties] - 이벤트 속성
  static Future<void> logBusinessEvent({
    required String event,
    String? category,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final message = 'Business Event: $event${category != null ? ' ($category)' : ''}';

      await FirebaseCrashlytics.instance.log(message);

      // 속성들을 커스텀 키로 설정
      if (properties != null) {
        for (final entry in properties.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            'event_${entry.key}',
            entry.value.toString(),
          );
        }
      }

      logger.i(message);

    } catch (e) {
      logger.e('Failed to log business event', error: e);
    }
  }

  /// 에러 정보와 함께 상세 로깅 (AppException 전용)
  /// [exception] - AppException 인스턴스
  /// [context] - 추가 컨텍스트
  static Future<void> logAppException(
      AppException exception, {
        Map<String, dynamic>? context,
      }) async {
    try {
      // AppException의 상세 정보 추출
      final errorData = {
        'exception_type': exception.runtimeType.toString(),
        'exception_message': exception.message,
        'exception_code': exception.code ?? 'no_code',
        'exception_severity': exception.severity.name,
        'exception_retryable': exception.isRetryable.toString(),
        'exception_user_friendly': exception.isUserFriendly.toString(),
        ...?context,
      };

      // Firebase Crashlytics에 기록
      await FirebaseCrashlytics.instance.recordError(
        exception,
        null,
        fatal: exception.severity == ErrorSeverity.critical,
        information: errorData.entries.map((e) =>
            DiagnosticsProperty(e.key, e.value)
        ).toList(),
      );

      // 커스텀 키 설정
      for (final entry in errorData.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(
          entry.key,
          entry.value.toString(),
        );
      }

      // 심각도에 따른 로컬 로그
      switch (exception.severity) {
        case ErrorSeverity.low:
          logger.i('AppException (${exception.severity.name}): ${exception.message}');
          break;
        case ErrorSeverity.medium:
          logger.w('AppException (${exception.severity.name}): ${exception.message}');
          break;
        case ErrorSeverity.high:
        case ErrorSeverity.critical:
          logger.e('AppException (${exception.severity.name}): ${exception.message}', error: exception);
          break;
      }

    } catch (e) {
      logger.e('Failed to log AppException', error: e);
    }
  }

  /// Crashlytics 수집 활성화/비활성화
  /// [enabled] - 수집 여부
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      logger.i('Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      logger.e('Failed to set Crashlytics collection enabled', error: e);
    }
  }

  /// 테스트용 크래시 발생 (디버그 모드에서만)
  static void testCrash() {
    if (kDebugMode) {
      logger.w('Triggering test crash for Crashlytics');
      FirebaseCrashlytics.instance.crash();
    } else {
      logger.w('Test crash is only available in debug mode');
    }
  }

  /// 로그 레벨별 편의 메서드들
  static void logDebug(String message, {Map<String, dynamic>? context}) {
    logger.d(message);
    if (context != null) {
      _setContextKeys(context, 'debug');
    }
  }

  static void logInfo(String message, {Map<String, dynamic>? context}) {
    logger.i(message);
    if (context != null) {
      _setContextKeys(context, 'info');
    }
  }

  static void logWarning(String message, {Map<String, dynamic>? context}) {
    logger.w(message);
    if (context != null) {
      _setContextKeys(context, 'warning');
    }
  }

  /// 컨텍스트 키 설정 헬퍼
  static void _setContextKeys(Map<String, dynamic> context, String level) {
    try {
      for (final entry in context.entries) {
        FirebaseCrashlytics.instance.setCustomKey(
          '${level}_${entry.key}',
          entry.value.toString(),
        );
      }
    } catch (e) {
      logger.e('Failed to set context keys', error: e);
    }
  }
}