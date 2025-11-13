/// 앱 예외 기본 클래스
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
  String toString() =>
      '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

/// 네트워크 예외
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 서버 예외
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });
}

/// 인증 예외
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 검증 예외
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });
}

/// 데이터 파싱 예외
class DataParsingException extends AppException {
  const DataParsingException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 권한 예외
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 위치 예외
class LocationException extends AppException {
  const LocationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 보안 예외
class SecurityException extends AppException {
  const SecurityException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 캐시 예외
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 일반 비즈니스 로직 예외
class BusinessException extends AppException {
  const BusinessException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 일반 앱 예외 (하위 호환성을 위해 유지)
class GeneralAppException extends AppException {
  const GeneralAppException(
    super.message, [
    String? code,
  ]) : super(code: code);
}
