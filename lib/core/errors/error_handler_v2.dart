import 'package:dio/dio.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

/// 개선된 에러 핸들러 (기존 error_handler.dart와 공존)
class ErrorHandlerV2 {
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('연결 시간이 초과되었습니다', 'TIMEOUT');

      case DioExceptionType.connectionError:
        return const NetworkException('네트워크 연결을 확인해주세요', 'NO_NETWORK');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _getServerErrorMessage(statusCode);
        return ServerException(message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return const GeneralAppException('요청이 취소되었습니다', 'CANCELLED');

      default:
        return const GeneralAppException('알 수 없는 오류가 발생했습니다', 'UNKNOWN');
    }
  }

  static String _getServerErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다';
      case 401:
        return '인증이 필요합니다';
      case 403:
        return '접근 권한이 없습니다';
      case 404:
        return '요청한 정보를 찾을 수 없습니다';
      case 500:
        return '서버 오류가 발생했습니다';
      default:
        return '서버 오류가 발생했습니다 (코드: $statusCode)';
    }
  }

  static AppException handleError(dynamic error) {
    if (error is AppException) return error;
    if (error is DioException) return handleDioError(error);
    return GeneralAppException(error.toString(), 'GENERAL_ERROR');
  }

  static String getUserMessage(AppException error) {
    return error.message;
  }
}
