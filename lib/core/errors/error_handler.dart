import 'package:dio/dio.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/constants/app_messages.dart';

/// 통합된 에러 핸들러
class ErrorHandler {
  /// DioException을 AppException으로 변환
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(ErrorMessages.timeout, 'TIMEOUT');

      case DioExceptionType.connectionError:
        return const NetworkException(ErrorMessages.network, 'NO_NETWORK');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseMsg = error.response?.data?['message'];
        final message = responseMsg ?? _getServerErrorMessage(statusCode);

        if (statusCode == 401) {
          return AuthException(message, 'UNAUTHORIZED');
        } else if (statusCode == 403) {
          return AuthException(message, 'FORBIDDEN');
        } else if (statusCode == 404) {
          return ServerException(message, statusCode: statusCode, code: 'NOT_FOUND');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(ErrorMessages.server, statusCode: statusCode);
        } else {
          return ServerException(message, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const GeneralAppException('요청이 취소되었습니다', 'CANCELLED');

      default:
        return GeneralAppException('알 수 없는 오류: ${error.message}', 'UNKNOWN');
    }
  }

  /// HTTP 상태 코드에 따른 에러 메시지
  static String _getServerErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다';
      case 401:
        return ErrorMessages.unauthorized;
      case 403:
        return ErrorMessages.forbidden;
      case 404:
        return ErrorMessages.notFound;
      case 408:
        return ErrorMessages.timeout;
      case 429:
        return '너무 많은 요청이 발생했습니다';
      case 500:
      case 502:
      case 503:
        return ErrorMessages.server;
      default:
        return statusCode != null ? '서버 오류가 발생했습니다 (코드: $statusCode)' : ErrorMessages.server;
    }
  }

  /// 일반 Exception을 AppException으로 변환
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    } else if (error is DioException) {
      return handleDioError(error);
    } else if (error is FormatException) {
      return DataParsingException('${ErrorMessages.dataFormat}: ${error.message}');
    } else if (error is TypeError) {
      return const DataParsingException(ErrorMessages.dataFormat);
    } else if (error.toString().contains('SocketException')) {
      return const NetworkException(ErrorMessages.network, 'SOCKET_ERROR');
    } else {
      return GeneralAppException(error.toString(), 'GENERAL_ERROR');
    }
  }

  /// 사용자 친화적 메시지 반환
  static String getUserMessage(AppException exception) {
    // 특정 코드에 대한 커스텀 메시지
    if (exception.code != null) {
      switch (exception.code) {
        case 'TIMEOUT':
          return ErrorMessages.timeout;
        case 'NO_NETWORK':
        case 'SOCKET_ERROR':
          return ErrorMessages.network;
        case 'UNAUTHORIZED':
          return ErrorMessages.unauthorized;
        case 'FORBIDDEN':
          return ErrorMessages.forbidden;
        case 'NOT_FOUND':
          return ErrorMessages.notFound;
      }
    }

    // 예외 타입별 기본 메시지
    if (exception is NetworkException) {
      return exception.message.isNotEmpty ? exception.message : ErrorMessages.network;
    } else if (exception is ServerException) {
      return exception.message.isNotEmpty ? exception.message : ErrorMessages.server;
    } else if (exception is AuthException) {
      return exception.message.isNotEmpty ? exception.message : ErrorMessages.unauthorized;
    } else if (exception is DataParsingException) {
      return ErrorMessages.dataFormat;
    } else if (exception is PermissionException) {
      return '필요한 권한이 없습니다';
    } else if (exception is ValidationException) {
      return exception.message.isNotEmpty ? exception.message : '입력값을 확인해주세요';
    } else if (exception is CacheException) {
      return '캐시 처리 중 오류가 발생했습니다';
    } else {
      return exception.message.isNotEmpty ? exception.message : ErrorMessages.general;
    }
  }
}
