/// 앱 전용 Exception 클래스들
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

/// 네트워크 관련 예외
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// 서버 응답 예외
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(String message, {this.statusCode, String? code})
      : super(message, code);
}

/// 데이터 파싱 예외
class DataParsingException extends AppException {
  const DataParsingException(super.message);
}

/// 인증 관련 예외
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

/// 권한 관련 예외
class PermissionException extends AppException {
  const PermissionException(super.message);
}

/// 유효성 검증 예외
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException(super.message, {this.errors});
}

/// 캐시 관련 예외
class CacheException extends AppException {
  const CacheException(super.message);
}

/// 일반 앱 예외 (구체적 구현을 위한 클래스)
class GeneralAppException extends AppException {
  const GeneralAppException(super.message, [super.code]);
}
