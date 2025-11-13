// lib/core/exceptions/error_handler.dart

import 'package:dio/dio.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/app_messages.dart';

/// 에러 핸들러
class ErrorHandler {
  ErrorHandler._();

  /// 에러를 AppException으로 변환
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is TypeError) {
      return BusinessException(
        ErrorMessages.dataFormat,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return BusinessException(
        ErrorMessages.dataFormat,
        originalError: error,
      );
    }

    return BusinessException(
      error.toString(),
      originalError: error,
    );
  }

  /// Dio 에러 처리
  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          ErrorMessages.timeout,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return BusinessException(
          ErrorMessages.requestCancelled,
          originalError: error,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          ErrorMessages.network,
          originalError: error,
        );
    }
  }

  /// HTTP 응답 에러 처리
  static AppException _handleResponseError(Response? response) {
    if (response == null) {
      return const ServerException(ErrorMessages.noServerResponse);
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
        ErrorMessages.tooManyRequestsRetry,
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
        return ErrorMessages.badRequest;
      case 401:
        return ErrorMessages.unauthorized;
      case 403:
        return ErrorMessages.forbidden;
      case 404:
        return ErrorMessages.notFound;
      case 408:
        return ErrorMessages.requestTimeout;
      case 429:
        return ErrorMessages.tooManyRequests;
      case 500:
        return ErrorMessages.internalServerError;
      case 502:
        return ErrorMessages.badGateway;
      case 503:
        return ErrorMessages.serviceUnavailable;
      default:
        if (statusCode >= 500) {
          return ErrorMessages.serverError;
        } else if (statusCode >= 400) {
          return ErrorMessages.requestProcessError;
        }
        return ErrorMessages.unknownError;
    }
  }

  /// 사용자 친화적 메시지 변환
  static String getUserMessage(AppException exception) {
    // 특정 에러 타입에 대한 사용자 메시지
    if (exception is NetworkException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.network;
    }

    if (exception is AuthException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.authRequired;
    }

    if (exception is ValidationException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.inputValidation;
    }

    if (exception is PermissionException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.permissionRequired;
    }

    if (exception is LocationException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.locationError;
    }

    if (exception is ServerException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.server;
    }

    if (exception is CacheException) {
      return exception.message.isNotEmpty
          ? exception.message
          : ErrorMessages.cacheError;
    }

    return exception.message.isNotEmpty
        ? exception.message
        : ErrorMessages.unknownError;
  }

  static int? getStatusCode(AppException exception) {
    if (exception is ServerException) {
      return exception.statusCode;
    }

    if (exception.code != null) {
      return int.tryParse(exception.code!);
    }

    return null;
  }

  static bool isRetryable(AppException exception) {
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
