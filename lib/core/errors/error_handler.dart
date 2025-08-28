import 'package:dio/dio.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

/// 통합된 에러 핸들러
class ErrorHandler {
  /// DioException을 AppException으로 변환
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
        final responseMsg = error.response?.data?['message'];
        final message = responseMsg ?? _getServerErrorMessage(statusCode);

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
        return const GeneralAppException('요청이 취소되었습니다', 'CANCELLED');

      default:
        return GeneralAppException('알 수 없는 오류: ${error.message}', 'UNKNOWN');
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
      case 408:
        return '요청 시간이 초과되었습니다';
      case 429:
        return '너무 많은 요청이 발생했습니다';
      case 500:
        return '서버 오류가 발생했습니다';
      case 502:
        return '게이트웨이 오류가 발생했습니다';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다';
      default:
        return statusCode != null
            ? '서버 오류가 발생했습니다 (코드: $statusCode)'
            : '서버와의 통신 중 문제가 발생했습니다';
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
    } else if (error is TypeError) {
      return DataParsingException('데이터 타입 오류가 발생했습니다');
    } else if (error.toString().contains('SocketException')) {
      return const NetworkException('네트워크 연결을 확인해주세요', 'SOCKET_ERROR');
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
          return '연결 시간이 초과되었습니다. 다시 시도해주세요';
        case 'NO_NETWORK':
        case 'SOCKET_ERROR':
          return '네트워크 연결을 확인해주세요';
        case 'UNAUTHORIZED':
          return '인증이 필요합니다. 다시 로그인해주세요';
        case 'FORBIDDEN':
          return '접근 권한이 없습니다';
        case 'NOT_FOUND':
          return '요청한 정보를 찾을 수 없습니다';
      }
    }

    // 예외 타입별 기본 메시지
    if (exception is NetworkException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '네트워크 연결을 확인해주세요';
    } else if (exception is ServerException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '서버와의 통신 중 문제가 발생했습니다';
    } else if (exception is AuthException) {
      return exception.message.isNotEmpty ? exception.message : '인증이 필요합니다';
    } else if (exception is DataParsingException) {
      return '데이터를 불러오는 중 문제가 발생했습니다';
    } else if (exception is PermissionException) {
      return '필요한 권한이 없습니다';
    } else if (exception is ValidationException) {
      return exception.message.isNotEmpty ? exception.message : '입력값을 확인해주세요';
    } else if (exception is CacheException) {
      return '캐시 처리 중 오류가 발생했습니다';
    } else {
      return exception.message.isNotEmpty
          ? exception.message
          : '오류가 발생했습니다. 잠시 후 다시 시도해주세요';
    }
  }
}
