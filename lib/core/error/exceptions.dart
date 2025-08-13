// lib/core/error/exceptions.dart
/// 앱에서 사용하는 커스텀 예외 클래스들
/// 각 예외는 구체적인 상황을 나타내며 적절한 사용자 메시지를 포함

/// 기본 앱 예외 클래스 (구체적인 클래스로 변경)
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
      this.message, {
        this.code,
        this.originalError,
      });

  @override
  String toString() => '${runtimeType}: $message';

  /// 예외 정보를 Map으로 변환 (로깅용)
  Map<String, dynamic> toMap() {
    return {
      'type': runtimeType.toString(),
      'message': message,
      'code': code,
      'original_error': originalError?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 사용자에게 표시할 수 있는 에러인지 확인
  bool get isUserFriendly => true;

  /// 재시도 가능한 에러인지 확인
  bool get isRetryable => false;

  /// 에러 심각도 (로깅 레벨 결정용)
  ErrorSeverity get severity => ErrorSeverity.medium;
}

/// 에러 심각도 열거형
enum ErrorSeverity {
  low,      // 정보성 에러 (사용자에게 알림만)
  medium,   // 일반적인 에러 (로그 기록 + 사용자 알림)
  high,     // 중요한 에러 (상세 로그 + 관리자 알림)
  critical, // 치명적 에러 (즉시 대응 필요)
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

  @override
  bool get isRetryable => true;

  @override
  ErrorSeverity get severity => ErrorSeverity.medium;
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

  @override
  bool get isRetryable {
    // 5xx 에러는 재시도 가능, 4xx 에러는 재시도 불가
    return statusCode >= 500;
  }

  @override
  ErrorSeverity get severity {
    if (statusCode >= 500) return ErrorSeverity.high;
    if (statusCode == 429) return ErrorSeverity.medium; // Too Many Requests
    return ErrorSeverity.low;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['status_code'] = statusCode;
    return map;
  }
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

  @override
  ErrorSeverity get severity => ErrorSeverity.high;

  @override
  bool get isRetryable => false; // 인증 에러는 일반적으로 재시도 불가
}

/// 캐시 관련 예외
class CacheException extends AppException {
  const CacheException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.low;

  @override
  bool get isRetryable => true; // 캐시 에러는 재시도 가능
}

/// 데이터 파싱 관련 예외
class ParseException extends AppException {
  const ParseException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.medium;

  @override
  bool get isRetryable => false; // 파싱 에러는 데이터 자체 문제이므로 재시도 불가
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

  @override
  ErrorSeverity get severity => ErrorSeverity.low;

  @override
  bool get isRetryable => false; // 유효성 검사 에러는 사용자 수정 필요

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    if (fieldErrors != null) {
      map['field_errors'] = fieldErrors;
    }
    return map;
  }

  /// 특정 필드의 에러 메시지 가져오기
  String? getFieldError(String fieldName) {
    return fieldErrors?[fieldName];
  }

  /// 필드 에러가 있는지 확인
  bool hasFieldErrors() {
    return fieldErrors != null && fieldErrors!.isNotEmpty;
  }
}

/// 권한 관련 예외
class PermissionException extends AppException {
  const PermissionException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.medium;

  @override
  bool get isRetryable => true; // 권한은 사용자가 허용하면 재시도 가능
}

/// 요청 취소 관련 예외
class CancelException extends AppException {
  const CancelException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.low;

  @override
  bool get isRetryable => true; // 취소된 요청은 재시도 가능

  @override
  bool get isUserFriendly => false; // 사용자에게 굳이 알릴 필요 없음
}

/// 파일 관련 예외
class FileException extends AppException {
  const FileException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.medium;

  @override
  bool get isRetryable => true; // 파일 작업은 재시도 가능할 수 있음
}

/// 타임아웃 관련 예외
class TimeoutException extends AppException {
  final Duration? timeout;

  const TimeoutException(
      String message, {
        this.timeout,
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.medium;

  @override
  bool get isRetryable => true; // 타임아웃은 재시도 가능

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    if (timeout != null) {
      map['timeout_seconds'] = timeout!.inSeconds;
    }
    return map;
  }
}

/// 일반적인 예외 (알 수 없는 에러용)
class UnknownException extends AppException {
  const UnknownException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'UnknownException: $message';

  @override
  ErrorSeverity get severity => ErrorSeverity.high; // 알 수 없는 에러는 높은 심각도

  @override
  bool get isRetryable => false; // 알 수 없는 에러는 기본적으로 재시도 불가
}

/// 비즈니스 로직 관련 예외
class BusinessException extends AppException {
  const BusinessException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.medium;

  @override
  bool get isRetryable => false; // 비즈니스 로직 에러는 재시도 불가
}

/// 설정 관련 예외
class ConfigurationException extends AppException {
  const ConfigurationException(
      String message, {
        String? code,
        dynamic originalError,
      }) : super(message, code: code, originalError: originalError);

  @override
  ErrorSeverity get severity => ErrorSeverity.critical; // 설정 에러는 치명적

  @override
  bool get isRetryable => false; // 설정 에러는 재시도 불가
}

/// 예외 유틸리티 클래스
class ExceptionUtils {
  /// 예외에서 사용자 친화적인 메시지 추출
  static String getUserMessage(AppException exception) {
    return exception.message;
  }

  /// 예외가 재시도 가능한지 확인
  static bool canRetry(Exception exception) {
    if (exception is AppException) {
      return exception.isRetryable;
    }
    return false;
  }

  /// 예외의 심각도 가져오기
  static ErrorSeverity getSeverity(Exception exception) {
    if (exception is AppException) {
      return exception.severity;
    }
    return ErrorSeverity.medium;
  }

  /// 예외를 Map으로 변환 (로깅용)
  static Map<String, dynamic> toMap(Exception exception) {
    if (exception is AppException) {
      return exception.toMap();
    }
    return {
      'type': exception.runtimeType.toString(),
      'message': exception.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}