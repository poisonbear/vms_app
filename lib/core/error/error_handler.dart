import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'exceptions.dart';
import '../../utils/logger.dart';

/// 에러 메시지 상수 (국제화 준비)
class ErrorMessages {
  // 네트워크 관련
  static const String networkConnection = 'error.network.connection';
  static const String networkTimeout = 'error.network.timeout';
  static const String networkCertificate = 'error.network.certificate';

  // 인증 관련
  static const String authRequired = 'error.auth.required';
  static const String authInvalidCredentials = 'error.auth.invalid_credentials';
  static const String authExpired = 'error.auth.expired';
  static const String authPermissionDenied = 'error.auth.permission_denied';

  // 서버 관련
  static const String serverError = 'error.server.internal';
  static const String serverNotFound = 'error.server.not_found';
  static const String serverBadRequest = 'error.server.bad_request';
  static const String serverTooManyRequests = 'error.server.too_many_requests';

  // 데이터 관련
  static const String dataParseError = 'error.data.parse';
  static const String dataValidationError = 'error.data.validation';

  // 일반적인 에러
  static const String unknownError = 'error.unknown';
  static const String operationCancelled = 'error.operation.cancelled';

  // Firebase 관련
  static const String firebasePermissionDenied = 'error.firebase.permission_denied';
  static const String firebaseUnavailable = 'error.firebase.unavailable';
  static const String firebaseDeadlineExceeded = 'error.firebase.deadline_exceeded';
}

/// 에러 심각도 레벨
enum ErrorSeverity { low, medium, high, critical }

/// 에러 컨텍스트 정보
class ErrorContext {
  final String operation;
  final String? userId;
  final String? screen;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;

  ErrorContext({
    required this.operation,
    this.userId,
    this.screen,
    this.additionalData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'user_id': userId,
      'screen': screen,
      'additional_data': additionalData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 중앙 집중식 에러 처리 클래스 (개선된 버전)
class ErrorHandler {
  ErrorHandler._();

  // 에러 타입별 메시지 매핑
  static final Map<Type, String> _errorMessageMap = {
    NetworkException: ErrorMessages.networkConnection,
    AuthException: ErrorMessages.authRequired,
    ValidationException: ErrorMessages.dataValidationError,
    PermissionException: ErrorMessages.authPermissionDenied,
    TimeoutException: ErrorMessages.networkTimeout,
    ServerException: ErrorMessages.serverError,
    ParseException: ErrorMessages.dataParseError,
    CancelException: ErrorMessages.operationCancelled,
  };

  // Firebase 에러 코드 매핑
  static final Map<String, String> _firebaseErrorMap = {
    'user-not-found': ErrorMessages.authInvalidCredentials,
    'wrong-password': ErrorMessages.authInvalidCredentials,
    'invalid-credential': ErrorMessages.authInvalidCredentials,
    'email-already-in-use': 'error.auth.email_already_in_use',
    'weak-password': 'error.auth.weak_password',
    'invalid-email': 'error.auth.invalid_email',
    'user-disabled': 'error.auth.user_disabled',
    'too-many-requests': ErrorMessages.serverTooManyRequests,
    'operation-not-allowed': ErrorMessages.authPermissionDenied,
    'network-request-failed': ErrorMessages.networkConnection,
    'permission-denied': ErrorMessages.firebasePermissionDenied,
    'unavailable': ErrorMessages.firebaseUnavailable,
    'deadline-exceeded': ErrorMessages.firebaseDeadlineExceeded,
  };

  /// 에러를 적절한 AppException으로 변환
  /// [error] - 발생한 에러
  /// [context] - 에러 컨텍스트 정보
  /// [stackTrace] - 스택 트레이스 (선택사항)
  static AppException handleError(
      dynamic error, {
        ErrorContext? context,
        StackTrace? stackTrace,
      }) {
    // 에러 로깅 (상세 정보 포함)
    _logError(error, context, stackTrace);

    // 이미 AppException인 경우 그대로 반환
    if (error is AppException) {
      return error;
    }

    // 타입별 에러 처리
    if (error is DioException) {
      return _handleDioError(error, context);
    }

    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error, context);
    }

    if (error is FirebaseException) {
      return _handleFirebaseError(error, context);
    }

    // 기타 알려진 에러들
    if (error is FormatException) {
      return ParseException(
        _getLocalizedMessage(ErrorMessages.dataParseError),
        code: 'format_error',
        originalError: error,
      );
    }

    if (error is TypeError) {
      return ParseException(
        _getLocalizedMessage(ErrorMessages.dataParseError),
        code: 'type_error',
        originalError: error,
      );
    }

    if (error is ArgumentError) {
      return ValidationException(
        _getLocalizedMessage(ErrorMessages.dataValidationError),
        code: 'argument_error',
        originalError: error,
      );
    }

    // 알 수 없는 에러
    return AppException(
      _getLocalizedMessage(ErrorMessages.unknownError),
      code: 'unknown_error',
      originalError: error,
    );
  }

  /// Dio 에러를 AppException으로 변환
  static AppException _handleDioError(DioException error, ErrorContext? context) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          _getLocalizedMessage(ErrorMessages.networkTimeout),
          code: error.type.name,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error, context);

      case DioExceptionType.cancel:
        return CancelException(
          _getLocalizedMessage(ErrorMessages.operationCancelled),
          code: 'request_cancelled',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          _getLocalizedMessage(ErrorMessages.networkConnection),
          code: 'connection_error',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          _getLocalizedMessage(ErrorMessages.networkCertificate),
          code: 'certificate_error',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          _getLocalizedMessage(ErrorMessages.networkConnection),
          code: 'network_unknown',
          originalError: error,
        );
    }
  }

  /// HTTP 응답 에러 처리 (개선된 버전)
  static AppException _handleBadResponse(DioException error, ErrorContext? context) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    // 서버에서 온 에러 메시지 파싱 시도
    String? serverMessage = _extractServerMessage(responseData);

    switch (statusCode) {
      case 400:
        return ValidationException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.serverBadRequest),
          code: 'bad_request',
          originalError: error,
          fieldErrors: _extractFieldErrors(responseData),
        );

      case 401:
        return AuthException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.authRequired),
          code: 'unauthorized',
          originalError: error,
        );

      case 403:
        return PermissionException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.authPermissionDenied),
          code: 'forbidden',
          originalError: error,
        );

      case 404:
        return ServerException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.serverNotFound),
          statusCode: statusCode,
          code: 'not_found',
          originalError: error,
        );

      case 422:
        return ValidationException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.dataValidationError),
          code: 'unprocessable_entity',
          originalError: error,
          fieldErrors: _extractFieldErrors(responseData),
        );

      case 429:
        return ServerException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.serverTooManyRequests),
          statusCode: statusCode,
          code: 'too_many_requests',
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.serverError),
          statusCode: statusCode,
          code: 'server_error',
          originalError: error,
        );

      default:
        return ServerException(
          serverMessage ?? _getLocalizedMessage(ErrorMessages.serverError),
          statusCode: statusCode,
          code: 'http_error',
          originalError: error,
        );
    }
  }

  /// Firebase Auth 에러 처리 (개선된 버전)
  static AppException _handleFirebaseAuthError(
      FirebaseAuthException error,
      ErrorContext? context,
      ) {
    final messageKey = _firebaseErrorMap[error.code] ?? ErrorMessages.authRequired;

    return AuthException(
      _getLocalizedMessage(messageKey),
      code: error.code,
      originalError: error,
    );
  }

  /// Firebase 일반 에러 처리 (개선된 버전)
  static AppException _handleFirebaseError(
      FirebaseException error,
      ErrorContext? context,
      ) {
    final messageKey = _firebaseErrorMap[error.code] ?? ErrorMessages.serverError;

    return ServerException(
      _getLocalizedMessage(messageKey),
      statusCode: 0,
      code: error.code,
      originalError: error,
    );
  }

  /// 서버 응답에서 에러 메시지 추출
  static String? _extractServerMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // 일반적인 에러 메시지 필드들 확인
      final messageFields = ['message', 'error', 'detail', 'description', 'msg'];

      for (final field in messageFields) {
        final value = responseData[field];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }

      // 중첩된 에러 객체 확인
      if (responseData['error'] is Map<String, dynamic>) {
        final errorObject = responseData['error'] as Map<String, dynamic>;
        for (final field in messageFields) {
          final value = errorObject[field];
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }
    }

    return null;
  }

  /// 필드별 에러 정보 추출
  static Map<String, String>? _extractFieldErrors(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Laravel 스타일 validation errors
      if (responseData['errors'] is Map<String, dynamic>) {
        final errors = responseData['errors'] as Map<String, dynamic>;
        final fieldErrors = <String, String>{};

        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            fieldErrors[key] = value.first.toString();
          } else if (value is String) {
            fieldErrors[key] = value;
          }
        });

        return fieldErrors.isNotEmpty ? fieldErrors : null;
      }

      // 기타 형태의 field errors
      if (responseData['field_errors'] is Map<String, dynamic>) {
        return Map<String, String>.from(responseData['field_errors']);
      }
    }

    return null;
  }

  /// 사용자 친화적인 에러 메시지 반환 (개선된 버전)
  /// [exception] - AppException
  /// [fallbackToGeneric] - 일반적인 메시지로 폴백할지 여부
  static String getUserFriendlyMessage(
      AppException exception, {
        bool fallbackToGeneric = true,
      }) {
    // 예외 타입별 기본 메시지
    String messageKey;

    if (exception is NetworkException) {
      messageKey = ErrorMessages.networkConnection;
    } else if (exception is AuthException) {
      messageKey = ErrorMessages.authRequired;
    } else if (exception is ValidationException) {
      messageKey = ErrorMessages.dataValidationError;
    } else if (exception is PermissionException) {
      messageKey = ErrorMessages.authPermissionDenied;
    } else if (exception is TimeoutException) {
      messageKey = ErrorMessages.networkTimeout;
    } else if (exception is ServerException) {
      // 서버 상태 코드에 따른 메시지
      switch (exception.statusCode) {
        case 500:
        case 502:
        case 503:
        case 504:
          messageKey = ErrorMessages.serverError;
          break;
        default:
          return exception.message;
      }
    } else {
      return exception.message;
    }

    // 국제화된 메시지 반환
    final localizedMessage = _getLocalizedMessage(messageKey);

    // 폴백 옵션 확인
    if (localizedMessage == messageKey && fallbackToGeneric) {
      return exception.message;
    }

    return localizedMessage;
  }

  /// 에러 심각도 평가
  static ErrorSeverity getErrorSeverity(AppException exception) {
    if (exception is NetworkException || exception is TimeoutException) {
      return ErrorSeverity.medium;
    }

    if (exception is AuthException) {
      return ErrorSeverity.high;
    }

    if (exception is ServerException) {
      if (exception.statusCode >= 500) {
        return ErrorSeverity.high;
      } else {
        return ErrorSeverity.medium;
      }
    }

    if (exception is ValidationException || exception is ParseException) {
      return ErrorSeverity.low;
    }

    return ErrorSeverity.medium;
  }

  /// 재시도 가능한 에러인지 확인
  static bool isRetryableError(AppException exception) {
    if (exception is NetworkException) {
      return true;
    }

    if (exception is TimeoutException) {
      return true;
    }

    if (exception is ServerException) {
      final retryableCodes = [500, 502, 503, 504, 429];
      return retryableCodes.contains(exception.statusCode);
    }

    return false;
  }

  /// 국제화된 메시지 가져오기 (추후 국제화 시스템과 연동)
  static String _getLocalizedMessage(String messageKey) {
    // 현재는 기본 한국어 메시지 반환
    // 추후 국제화 시스템과 연동 예정
    return _getKoreanMessage(messageKey);
  }

  /// 한국어 메시지 매핑
  static String _getKoreanMessage(String messageKey) {
    const koreanMessages = {
      ErrorMessages.networkConnection: '네트워크 연결을 확인하고 다시 시도해주세요',
      ErrorMessages.networkTimeout: '연결 시간이 초과되었습니다. 다시 시도해주세요',
      ErrorMessages.networkCertificate: '보안 인증서 오류가 발생했습니다',
      ErrorMessages.authRequired: '로그인이 필요하거나 세션이 만료되었습니다',
      ErrorMessages.authInvalidCredentials: '아이디 또는 비밀번호를 확인해주세요',
      ErrorMessages.authExpired: '인증이 만료되었습니다. 다시 로그인해주세요',
      ErrorMessages.authPermissionDenied: '이 기능을 사용할 권한이 없습니다',
      ErrorMessages.serverError: '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요',
      ErrorMessages.serverNotFound: '요청한 리소스를 찾을 수 없습니다',
      ErrorMessages.serverBadRequest: '잘못된 요청입니다',
      ErrorMessages.serverTooManyRequests: '너무 많은 요청입니다. 잠시 후 다시 시도해주세요',
      ErrorMessages.dataParseError: '데이터 처리 중 오류가 발생했습니다',
      ErrorMessages.dataValidationError: '입력하신 정보를 다시 확인해주세요',
      ErrorMessages.unknownError: '알 수 없는 오류가 발생했습니다',
      ErrorMessages.operationCancelled: '작업이 취소되었습니다',
      ErrorMessages.firebasePermissionDenied: 'Firebase 권한이 없습니다',
      ErrorMessages.firebaseUnavailable: 'Firebase 서비스를 일시적으로 사용할 수 없습니다',
      ErrorMessages.firebaseDeadlineExceeded: 'Firebase 요청 시간이 초과되었습니다',
    };

    return koreanMessages[messageKey] ?? messageKey;
  }

  /// 에러 로깅 (상세 정보 포함)
  static void _logError(
      dynamic error,
      ErrorContext? context,
      StackTrace? stackTrace,
      ) {
    try {
      final severity = error is AppException
          ? getErrorSeverity(error)
          : ErrorSeverity.medium;

      final logData = {
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'severity': severity.name,
        'context': context?.toMap(),
        'stack_trace': stackTrace?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 심각도에 따른 로그 레벨 선택
      switch (severity) {
        case ErrorSeverity.low:
          logger.i('Low severity error occurred', error, stackTrace);
          break;
        case ErrorSeverity.medium:
          logger.w('Medium severity error occurred', error, stackTrace);
          break;
        case ErrorSeverity.high:
        case ErrorSeverity.critical:
          logger.e('High/Critical severity error occurred', error, stackTrace);
          break;
      }

      // 추가 로그 데이터 출력 (디버그 모드)
      if (kDebugMode) {
        logger.d('Error details: $logData');
      }

    } catch (loggingError) {
      // 로깅 자체에서 에러가 발생한 경우 기본 로그만 남김
      if (kDebugMode) {
        debugPrint('Failed to log error: $loggingError');
        debugPrint('Original error: $error');
      }
    }
  }

  /// 에러 통계 수집 (선택적 기능)
  static final Map<String, int> _errorCounts = {};

  static void recordErrorOccurrence(AppException exception) {
    final errorType = exception.runtimeType.toString();
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
  }

  static Map<String, int> getErrorStatistics() {
    return Map<String, int>.from(_errorCounts);
  }

  static void clearErrorStatistics() {
    _errorCounts.clear();
  }
}