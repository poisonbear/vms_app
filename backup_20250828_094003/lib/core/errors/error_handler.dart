import 'package:dio/dio.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

class ErrorHandler {
  /// DioException을 AppException으로 변환
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('연결 시간이 초과되었습니다', 'TIMEOUT');

      case DioExceptionType.connectionError:
        return const NetworkException('네트워크 연결을 확인해주세요', 'CONNECTION_ERROR');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? '서버 오류가 발생했습니다';

        if (statusCode == 401) {
          return AuthException(message, 'UNAUTHORIZED');
        } else if (statusCode == 403) {
          return AuthException(message, 'FORBIDDEN');
        } else if (statusCode == 404) {
          return ServerException(message,
              statusCode: statusCode, code: 'NOT_FOUND');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException('서버 내부 오류가 발생했습니다', statusCode: statusCode);
        } else {
          return ServerException(message, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const NetworkException('요청이 취소되었습니다', 'CANCELLED');

      default:
        return NetworkException('알 수 없는 오류가 발생했습니다: ${error.message}');
    }
  }

  /// 일반 Exception을 AppException으로 변환
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    } else if (error is DioException) {
      return handleDioError(error);
    } else if (error is FormatException) {
      return DataParsingException('데이터 형식이 올바르지 않습니다: ${error.message}');
    } else {
      return GeneralAppException(error.toString());
    }
  }

  /// 사용자 친화적 메시지 반환
  static String getUserMessage(AppException exception) {
    if (exception is NetworkException) {
      return '네트워크 연결을 확인해주세요';
    } else if (exception is ServerException) {
      return '서버와의 통신 중 문제가 발생했습니다';
    } else if (exception is AuthException) {
      return '인증이 필요합니다. 다시 로그인해주세요';
    } else if (exception is DataParsingException) {
      return '데이터를 불러오는 중 문제가 발생했습니다';
    } else if (exception is PermissionException) {
      return '필요한 권한이 없습니다';
    } else if (exception is ValidationException) {
      return '입력값을 확인해주세요';
    } else if (exception is CacheException) {
      return '캐시 처리 중 오류가 발생했습니다';
    } else {
      return '오류가 발생했습니다. 잠시 후 다시 시도해주세요';
    }
  }
}
