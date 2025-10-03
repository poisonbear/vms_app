// lib/core/infrastructure/network_client.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 네트워크 클라이언트
class NetworkClient {
  static NetworkClient? _instance;
  late final Dio _dio;

  NetworkClient._() {
    _initializeDio();
  }

  factory NetworkClient() {
    _instance ??= NetworkClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: AppDurations.seconds30,
      receiveTimeout: AppDurations.seconds100,
      sendTimeout: AppDurations.seconds30,
      headers: {
        'Content-Type': NetworkConstants.contentTypeJson,
        'Accept': NetworkConstants.contentTypeJson,
        'User-Agent': NetworkConstants.userAgent,
        ...NetworkConstants.defaultHeaders,
      },
    ));

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _RetryInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  static Options createOptions({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) {
    return Options(
      receiveTimeout: receiveTimeout ?? AppDurations.seconds30,
      sendTimeout: sendTimeout ?? AppDurations.seconds30,
      headers: headers,
      responseType: responseType,
    );
  }

  /// 네트워크 상태 확인
  Future<bool> isNetworkAvailable() async {
    try {
      final response = await _dio.get(
        'https://www.google.com',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ============================================
// Interceptors
// ============================================

/// 로깅 인터셉터
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('🌐 [${options.method}] ${options.uri}');
    if (options.data != null) {
      AppLogger.d('📤 Request Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('✅ [${response.statusCode}] ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '❌ [${err.response?.statusCode ?? 'NO_STATUS'}] ${err.requestOptions.uri}',
      err,
    );
    handler.next(err);
  }
}

/// 재시도 인터셉터 (Exponential Backoff)
class _RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = err.requestOptions.extra['retry_attempt'] ?? 0;

    if (attempt >= maxRetries) {
      AppLogger.w('Max retries ($maxRetries) reached');
      return handler.next(err);
    }

    // Exponential backoff: 1초, 2초, 4초
    final delay = initialDelay * (1 << attempt);
    AppLogger.d('Retrying request (attempt ${attempt + 1}/$maxRetries) after ${delay.inSeconds}s');

    await Future.delayed(delay);
    err.requestOptions.extra['retry_attempt'] = attempt + 1;

    try {
      final response = await Dio().fetch(err.requestOptions);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // 타임아웃, 네트워크 에러, 5XX 서버 에러만 재시도
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

/// 에러 인터셉터
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = ErrorHandler.handleError(err);
    AppLogger.e('Network error: ${exception.message}', err);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }
}

// ============================================
// DioRequest - 하위 호환성
// ============================================

/// DioRequest (기존 코드 호환용)
class DioRequest {
  static DioRequest? _instance;
  late final NetworkClient _networkClient;

  DioRequest._() {
    _networkClient = NetworkClient();
  }

  factory DioRequest() {
    _instance ??= DioRequest._();
    return _instance!;
  }

  Dio get dio => _networkClient.dio;

  static Options createOptions({
    Duration? timeout,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) {
    return NetworkClient.createOptions(
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: headers,
      responseType: responseType,
    );
  }
}