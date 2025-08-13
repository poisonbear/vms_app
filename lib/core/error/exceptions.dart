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
  String toString() => '${runtimeType}: $message';
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