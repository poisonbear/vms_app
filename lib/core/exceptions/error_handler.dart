import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 통합된 에러 핸들러
class ErrorHandler {
  ErrorHandler._();

  /// 에러를 AppException으로 변환
  static AppException handleError(dynamic error) {
    AppLogger.e('Handling error: ${error.runtimeType} - $error');

    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is SocketException) {
      return NetworkException(
        '인터넷 연결을 확인해주세요',
        originalError: error,
      );
    }

    if (error is FormatException) {
      return ValidationException(
        '잘못된 데이터 형식입니다',
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return NetworkException(
        '요청 시간이 초과되었습니다',
        originalError: error,
      );
    }

    // 기본 에러
    return BusinessException(
      error?.toString() ?? '알 수 없는 오류가 발생했습니다',
      originalError: error,
    );
  }

  /// DioException 처리
  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          '연결 시간이 초과되었습니다',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return NetworkException(
          '요청이 취소되었습니다',
          originalError: error,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException(
            '인터넷 연결을 확인해주세요',
            originalError: error,
          );
        }
        return NetworkException(
          '네트워크 오류가 발생했습니다',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return SecurityException(
          '보안 인증서 오류가 발생했습니다',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          '서버 연결에 실패했습니다',
          originalError: error,
        );
    }
  }

  /// Response 에러 처리
  static AppException _handleResponseError(Response? response) {
    if (response == null) {
      return const ServerException('서버 응답이 없습니다');
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    String message = _extractErrorMessage(data) ??
        _getDefaultMessageForStatusCode(statusCode);

    // 특정 상태 코드별 처리
    if (statusCode == 400) {
      return ValidationException(
        message,
        code: '400',
        originalError: response.data,
      );
    }

    if (statusCode == 401) {
      return AuthException(
        message,
        code: '401',
        originalError: response.data,
      );
    }

    if (statusCode == 403) {
      return PermissionException(
        message,
        code: '403',
        originalError: response.data,
      );
    }

    if (statusCode == 404) {
      return ServerException(
        message,
        statusCode: statusCode,
        code: '404',
        originalError: response.data,
      );
    }

    if (statusCode == 408) {
      return NetworkException(
        message,
        code: '408',
        originalError: response.data,
      );
    }

    if (statusCode == 429) {
      return ServerException(
        '너무 많은 요청입니다. 잠시 후 다시 시도해주세요.',
        statusCode: statusCode,
        code: '429',
        originalError: response.data,
      );
    }

    if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
      return ServerException(
        message,
        statusCode: statusCode,
        code: statusCode.toString(),
        originalError: response.data,
      );
    }

    // 범위별 처리
    if (statusCode >= 500) {
      return ServerException(
        message,
        statusCode: statusCode,
        code: statusCode.toString(),
        originalError: response.data,
      );
    }

    if (statusCode >= 400) {
      return BusinessException(
        message,
        code: statusCode.toString(),
        originalError: response.data,
      );
    }

    // 그 외 모든 경우
    return BusinessException(
      message,
      originalError: response.data,
    );
  }

  /// 에러 메시지 추출
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) return data;

    if (data is Map) {
      // 다양한 에러 메시지 필드 체크
      final possibleKeys = ['message', 'error', 'msg', 'detail', 'reason'];
      for (final key in possibleKeys) {
        if (data.containsKey(key) && data[key] != null) {
          return data[key].toString();
        }
      }
    }

    return null;
  }

  /// 상태 코드별 기본 메시지
  static String _getDefaultMessageForStatusCode(int statusCode) {
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
        return '너무 많은 요청입니다';
      case 500:
        return '서버 내부 오류가 발생했습니다';
      case 502:
        return '게이트웨이 오류가 발생했습니다';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다';
      default:
        if (statusCode >= 500) {
          return '서버 오류가 발생했습니다';
        } else if (statusCode >= 400) {
          return '요청 처리 중 오류가 발생했습니다';
        }
        return '알 수 없는 오류가 발생했습니다';
    }
  }

  /// 사용자 친화적 메시지 변환
  static String getUserMessage(AppException exception) {
    // 특정 에러 타입에 대한 사용자 메시지
    if (exception is NetworkException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '네트워크 연결을 확인해주세요';
    }

    if (exception is AuthException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '로그인이 필요합니다';
    }

    if (exception is ValidationException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '입력한 정보를 확인해주세요';
    }

    if (exception is PermissionException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '필요한 권한이 없습니다';
    }

    if (exception is LocationException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '위치 정보를 가져올 수 없습니다';
    }

    if (exception is ServerException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '서버와의 통신 중 문제가 발생했습니다';
    }

    if (exception is CacheException) {
      return exception.message.isNotEmpty
          ? exception.message
          : '캐시 처리 중 문제가 발생했습니다';
    }

    return exception.message.isNotEmpty
        ? exception.message
        : '알 수 없는 오류가 발생했습니다';
  }

  /// 에러 코드별 HTTP 상태 코드 반환
  static int? getStatusCode(AppException exception) {
    if (exception is ServerException) {
      return exception.statusCode;
    }

    if (exception.code != null) {
      return int.tryParse(exception.code!);
    }

    return null;
  }

  /// 재시도 가능한 에러인지 확인
  static bool isRetryable(AppException exception) {
    // 네트워크 타임아웃 에러는 재시도 가능
    if (exception is NetworkException) {
      return true;
    }

    // 서버 에러 중 일부는 재시도 가능
    if (exception is ServerException) {
      final statusCode = exception.statusCode;
      if (statusCode != null) {
        // 5XX 에러나 429(Too Many Requests)는 재시도 가능
        return statusCode >= 500 || statusCode == 429;
      }
    }

    return false;
  }

  /// 에러 로깅
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    final exception = handleError(error);
    AppLogger.e(
      'Error occurred: ${exception.runtimeType} - ${exception.message}',
      error,
      stackTrace,
    );
  }
}