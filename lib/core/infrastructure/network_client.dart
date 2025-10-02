// lib/core/infrastructure/network_client.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 🔧 개선: 통합 네트워크 클라이언트
class NetworkClient {
  static NetworkClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _tokenRefreshController = StreamController<bool>.broadcast();

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

    // 🔧 개선: Interceptor 순서 최적화
    _dio.interceptors.addAll([
      _LoggingInterceptor(), // 먼저 로깅
      _AuthInterceptor(this), // 인증 처리
      _RetryInterceptor(), // 재시도
      _ErrorInterceptor(), // 마지막에 에러 처리
    ]);
  }

  // 🔧 개선: 타임아웃 설정을 더 명확하게
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

  // ============================================
  // Credentials Management (보안 개선)
  // ============================================

  Future<void> saveCredentials(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.d('Credentials saved: $key');
    } catch (e) {
      AppLogger.e('Failed to save credentials', e);
      throw SecurityException('자격 증명 저장 실패', originalError: e);
    }
  }

  Future<String?> getCredentials(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.e('Failed to read credentials', e);
      return null;
    }
  }

  Future<void> deleteCredentials(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('Credentials deleted: $key');
    } catch (e) {
      AppLogger.e('Failed to delete credentials', e);
    }
  }

  Future<void> clearAllCredentials() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('All credentials cleared');
    } catch (e) {
      AppLogger.e('Failed to clear all credentials', e);
    }
  }

  // 🔧 신규: 토큰 새로고침 스트림
  Stream<bool> get tokenRefreshStream => _tokenRefreshController.stream;

  // 🔧 신규: 네트워크 상태 체크
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

  void dispose() {
    _tokenRefreshController.close();
  }
}

// ============================================
// Interceptors
// ============================================

/// 🔧 개선: 인증 인터셉터
class _AuthInterceptor extends Interceptor {
  final NetworkClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    try {
      final token = await _client.getCredentials('auth_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to add auth token',
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 에러 시 토큰 갱신 시도
    if (err.response?.statusCode == 401) {
      AppLogger.w('401 Unauthorized - attempting token refresh');
      // 토큰 갱신 로직은 별도 서비스에서 처리
      _client._tokenRefreshController.add(true);
    }
    handler.next(err);
  }
}

/// 🔧 개선: 로깅 인터셉터 (더 상세한 로깅)
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

/// 🔧 개선: 재시도 인터셉터 (Exponential Backoff 추가)
class _RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 재시도 가능한 에러인지 확인
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = err.requestOptions.extra['retry_attempt'] ?? 0;

    if (attempt >= maxRetries) {
      AppLogger.w('Max retries ($maxRetries) reached');
      return handler.next(err);
    }

    // Exponential backoff
    final delay = initialDelay * (1 << attempt); // 1초, 2초, 4초
    AppLogger.d('Retrying request (attempt ${attempt + 1}/$maxRetries) after ${delay.inSeconds}s');

    await Future.delayed(delay);

    // 재시도 카운트 증가
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
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}

/// 🔧 개선: 에러 인터셉터
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = ErrorHandler.handleError(err);
    AppLogger.e('Network error: ${exception.message}', err);

    // DioException을 AppException으로 변환하여 전달
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
// DioRequest - 하위 호환성 유지
// ============================================

/// 🔧 개선: 싱글톤 패턴 적용
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

  // 🔧 개선: createOptions도 NetworkClient 메서드 사용
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