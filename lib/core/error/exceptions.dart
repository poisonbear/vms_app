// lib/core/error/exceptions.dart
/// 앱에서 사용하는 커스텀 예외 클래스들
/// 각 예외는 구체적인 상황을 나타내며 적절한 사용자 메시지를 포함

/// 기본 앱 예외 클래스
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
      this.message, {
        this.code,
        this.originalError,
      });

  @override
  String toString() => 'AppException: $message';
}

/// 네트워크 관련 예외
class NetworkException extends AppException {
  const NetworkException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NetworkException: $message';
}

/// 서버 응답 관련 예외
class ServerException extends AppException {
  final int statusCode;

  const ServerException(
      String message, {
        required this.statusCode,
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// 인증 관련 예외
class AuthException extends AppException {
  const AuthException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'AuthException: $message';
}

/// 캐시 관련 예외
class CacheException extends AppException {
  const CacheException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

/// 데이터 파싱 관련 예외
class ParseException extends AppException {
  const ParseException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

/// 유효성 검사 관련 예외
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
      String message, {
        this.fieldErrors,
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

/// 권한 관련 예외
class PermissionException extends AppException {
  const PermissionException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

/// 요청 취소 관련 예외
class CancelException extends AppException {
  const CancelException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

/// 파일 관련 예외
class FileException extends AppException {
  const FileException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

/// 타임아웃 관련 예외
class TimeoutException extends AppException {
  const TimeoutException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);
}

// lib/core/error/error_handler.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'exceptions.dart';
import '../../logger.dart';

/// 중앙 집중식 에러 처리 클래스
/// 모든 예외를 적절한 AppException으로 변환하고 로깅
class ErrorHandler {
  ErrorHandler._();

  /// 에러를 적절한 AppException으로 변환
  /// [error] - 발생한 에러
  /// [stackTrace] - 스택 트레이스 (선택사항)
  static AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    // 로깅
    logger.e('Error occurred', error, stackTrace);

    // 이미 AppException인 경우 그대로 반환
    if (error is AppException) {
      return error;
    }

    // Dio 에러 처리
    if (error is DioException) {
      return _handleDioError(error);
    }

    // Firebase 에러 처리
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // 기타 알려진 에러들
    if (error is FormatException) {
      return ParseException(
        '데이터 형식이 올바르지 않습니다',
        originalError: error,
      );
    }

    if (error is TypeError) {
      return ParseException(
        '데이터 타입 오류가 발생했습니다',
        originalError: error,
      );
    }

    // 알 수 없는 에러
    return AppException(
      '알 수 없는 오류가 발생했습니다',
      originalError: error,
    );
  }

  /// Dio 에러를 AppException으로 변환
  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          '연결 시간이 초과되었습니다',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return CancelException(
          '요청이 취소되었습니다',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          '네트워크 연결을 확인해주세요',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          '보안 인증서 오류가 발생했습니다',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          '네트워크 오류가 발생했습니다',
          originalError: error,
        );
    }
  }

  /// HTTP 응답 에러 처리
  static AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    // 서버에서 온 에러 메시지 파싱 시도
    String message = '서버 오류가 발생했습니다';

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ??
          responseData['error'] ??
          responseData['detail'] ??
          message;
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
          message.isEmpty ? '잘못된 요청입니다' : message,
          originalError: error,
        );

      case 401:
        return AuthException(
          message.isEmpty ? '인증이 필요합니다' : message,
          originalError: error,
        );

      case 403:
        return PermissionException(
          message.isEmpty ? '접근 권한이 없습니다' : message,
          originalError: error,
        );

      case 404:
        return ServerException(
          message.isEmpty ? '요청한 리소스를 찾을 수 없습니다' : message,
          statusCode: statusCode,
          originalError: error,
        );

      case 422:
        return ValidationException(
          message.isEmpty ? '입력 데이터가 올바르지 않습니다' : message,
          originalError: error,
        );

      case 429:
        return ServerException(
          message.isEmpty ? '너무 많은 요청입니다. 잠시 후 다시 시도해주세요' : message,
          statusCode: statusCode,
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message.isEmpty ? '서버에 일시적인 문제가 발생했습니다' : message,
          statusCode: statusCode,
          originalError: error,
        );

      default:
        return ServerException(
          message,
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  /// Firebase Auth 에러 처리
  static AppException _handleFirebaseAuthError(FirebaseAuthException error) {
    String message;

    switch (error.code) {
      case 'user-not-found':
        message = '사용자를 찾을 수 없습니다';
        break;
      case 'wrong-password':
        message = '비밀번호가 올바르지 않습니다';
        break;
      case 'email-already-in-use':
        message = '이미 사용 중인 이메일입니다';
        break;
      case 'weak-password':
        message = '비밀번호가 너무 약합니다';
        break;
      case 'invalid-email':
        message = '이메일 형식이 올바르지 않습니다';
        break;
      case 'user-disabled':
        message = '비활성화된 계정입니다';
        break;
      case 'too-many-requests':
        message = '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요';
        break;
      case 'operation-not-allowed':
        message = '허용되지 않은 작업입니다';
        break;
      case 'network-request-failed':
        message = '네트워크 연결을 확인해주세요';
        break;
      default:
        message = '인증 오류가 발생했습니다';
        break;
    }

    return AuthException(
      message,
      code: error.code,
      originalError: error,
    );
  }

  /// Firebase 일반 에러 처리
  static AppException _handleFirebaseError(FirebaseException error) {
    String message;

    switch (error.code) {
      case 'permission-denied':
        message = '권한이 없습니다';
        break;
      case 'unavailable':
        message = '서비스를 일시적으로 사용할 수 없습니다';
        break;
      case 'deadline-exceeded':
        message = '요청 시간이 초과되었습니다';
        break;
      default:
        message = error.message ?? 'Firebase 오류가 발생했습니다';
        break;
    }

    return ServerException(
      message,
      statusCode: 0,
      code: error.code,
      originalError: error,
    );
  }

  /// 사용자 친화적인 에러 메시지 반환
  /// [exception] - AppException
  static String getUserFriendlyMessage(AppException exception) {
    // 각 예외 타입에 따른 기본 메시지 정의
    if (exception is NetworkException) {
      return '네트워크 연결을 확인하고 다시 시도해주세요';
    }

    if (exception is AuthException) {
      return '로그인이 필요하거나 세션이 만료되었습니다';
    }

    if (exception is ValidationException) {
      return '입력하신 정보를 다시 확인해주세요';
    }

    if (exception is PermissionException) {
      return '이 기능을 사용할 권한이 없습니다';
    }

    if (exception is TimeoutException) {
      return '요청 시간이 초과되었습니다. 다시 시도해주세요';
    }

    if (exception is ServerException) {
      // 서버 상태 코드에 따른 메시지
      switch (exception.statusCode) {
        case 500:
        case 502:
        case 503:
        case 504:
          return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요';
        default:
          return exception.message;
      }
    }

    // 기본 메시지 반환
    return exception.message;
  }
}

// lib/core/error/error_logger.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../logger.dart';
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

// lib/core/error/error_reporter.dart
import 'package:flutter/material.dart';
import 'exceptions.dart';
import 'error_handler.dart';
import 'error_logger.dart';
import '../../kdn/cmm_widget/common_widgets.dart';

/// 사용자에게 에러를 표시하는 리포터 클래스
class ErrorReporter {
  ErrorReporter._();

  /// 에러를 사용자에게 표시
  /// [context] - BuildContext
  /// [error] - 발생한 에러
  /// [showSnackBar] - 스낵바 표시 여부 (기본값: true)
  /// [onRetry] - 재시도 콜백 (선택사항)
  static void reportError(
      BuildContext context,
      dynamic error, {
        bool showSnackBar = true,
        VoidCallback? onRetry,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    // 에러 로깅
    ErrorLogger.logError(
      appException,
      context: {
        'screen': ModalRoute.of(context)?.settings.name ?? 'unknown',
        'error_type': appException.runtimeType.toString(),
      },
    );

    if (showSnackBar) {
      _showErrorSnackBar(context, message, appException, onRetry);
    }
  }

  /// 에러 스낵바 표시
  static void _showErrorSnackBar(
      BuildContext context,
      String message,
      AppException exception,
      VoidCallback? onRetry,
      ) {
    SnackBarType type = SnackBarType.error;

    // 예외 타입에 따른 스낵바 타입 결정
    if (exception is NetworkException) {
      type = SnackBarType.warning;
    } else if (exception is ValidationException) {
      type = SnackBarType.info;
    }

    CommonWidgets.showTopSnackBar(
      context,
      message,
      type: type,
      duration: const Duration(seconds: 4),
    );
  }

  /// 에러 다이얼로그 표시
  /// [context] - BuildContext
  /// [error] - 발생한 에러
  /// [title] - 다이얼로그 제목 (선택사항)
  /// [onRetry] - 재시도 콜백 (선택사항)
  /// [onCancel] - 취소 콜백 (선택사항)
  static void showErrorDialog(
      BuildContext context,
      dynamic error, {
        String? title,
        VoidCallback? onRetry,
        VoidCallback? onCancel,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? '오류'),
          content: Text(message),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                child: const Text('취소'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onRetry != null) {
                  onRetry();
                }
              },
              child: Text(onRetry != null ? '다시 시도' : '확인'),
            ),
          ],
        );
      },
    );
  }

  /// 전체 화면 에러 위젯
  /// [error] - 발생한 에러
  /// [onRetry] - 재시도 콜백 (선택사항)
  static Widget errorWidget(
      dynamic error, {
        VoidCallback? onRetry,
      }) {
    final appException = ErrorHandler.handleError(error);
    final message = ErrorHandler.getUserFriendlyMessage(appException);

    return CommonWidgets.emptyState(
      message: message,
      iconPath: 'assets/kdn/ros/img/circle-exclamation.svg',
      actionText: onRetry != null ? '다시 시도' : null,
      onAction: onRetry,
    );
  }
}