// lib/core/infrastructure/network_client.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/services/security/secure_storage_service.dart';

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

    // 인터셉터 순서
    // 1. 로깅 (모든 요청/응답 기록)
    // 2. 토큰 갱신 (401 에러 시 자동 처리)
    // 3. 재시도 (네트워크/서버 에러 재시도)
    // 4. 에러 변환 (최종 에러 처리)
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _TokenRefreshInterceptor(),
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
    AppLogger.d('[${options.method}] ${options.uri}');
    if (options.data != null) {
      AppLogger.d('📤 Request Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('[${response.statusCode}] ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '[${err.response?.statusCode ?? 'NO_STATUS'}] ${err.requestOptions.uri}',
      err,
    );
    handler.next(err);
  }
}

/// 토큰 갱신 인터셉터
///
/// 401 Unauthorized 응답 시 Firebase 토큰을 자동으로 갱신하고 원래 요청을 재시도
class _TokenRefreshInterceptor extends Interceptor {
  static const String _retryKey = 'token_retry_attempted';
  static final SecureStorageService _secureStorage = SecureStorageService();

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // 401 에러이고, 아직 재시도하지 않은 경우에만 처리
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra[_retryKey] != true) {
      try {
        AppLogger.d('토큰 만료 감지 (401) - 자동 갱신 시도');

        // 현재 Firebase 사용자 확인
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          AppLogger.w('Firebase 사용자 정보 없음 - 로그아웃 필요');
          return handler.next(err);
        }

        // Firebase 토큰 강제 갱신
        final newToken = await user.getIdToken(true);

        if (newToken == null || newToken.isEmpty) {
          AppLogger.e('토큰 갱신 실패 - null 또는 빈 토큰');
          return handler.next(err);
        }

        AppLogger.d('Firebase 토큰 갱신 성공');
        AppLogger.d(
            '새 토큰: ${newToken.substring(0, 20)}... (길이: ${newToken.length})');

        // SecureStorage에 새 토큰 저장
        final saved = await _secureStorage.saveFirebaseToken(newToken);
        if (!saved) {
          AppLogger.w('새 토큰 저장 실패 (계속 진행)');
        }

        // 원래 요청을 새 토큰으로 재구성
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        // 무한 루프 방지 플래그
        requestOptions.extra[_retryKey] = true;

        AppLogger.d(
            '갱신된 토큰으로 요청 재시도: ${requestOptions.method} ${requestOptions.path}');

        // 새 Dio 인스턴스로 재시도 (인터셉터 중복 실행 방지)
        final response = await Dio().request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            contentType: requestOptions.contentType,
            responseType: requestOptions.responseType,
            receiveTimeout: requestOptions.receiveTimeout,
            sendTimeout: requestOptions.sendTimeout,
          ),
        );

        AppLogger.d('재시도 성공: ${response.statusCode}');
        return handler.resolve(response);
      } on FirebaseAuthException catch (e) {
        AppLogger.e('Firebase 토큰 갱신 실패: ${e.code} - ${e.message}');
        return handler.next(err);
      } on DioException catch (e) {
        AppLogger.e('재시도 요청 실패: ${e.message}');
        // 재시도도 실패한 경우 원래 에러 전달
        return handler.next(err);
      } catch (e) {
        AppLogger.e('토큰 갱신 중 예상치 못한 에러: $e');
        return handler.next(err);
      }
    }

    // 401이 아니거나 이미 재시도한 경우 다음 인터셉터로
    return handler.next(err);
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
      AppLogger.w('최대 재시도 횟수($maxRetries) 도달');
      return handler.next(err);
    }

    // Exponential backoff: 1초, 2초, 4초
    final delay = initialDelay * (1 << attempt);
    AppLogger.d('요청 재시도 (${attempt + 1}/$maxRetries) - ${delay.inSeconds}초 후');

    await Future.delayed(delay);
    err.requestOptions.extra['retry_attempt'] = attempt + 1;

    try {
      final response = await Dio().fetch(err.requestOptions);
      AppLogger.d('재시도 성공');
      return handler.resolve(response);
    } catch (e) {
      AppLogger.w('재시도 실패');
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // 타임아웃, 네트워크 에러, 5XX 서버 에러만 재시도
    // 401은 TokenRefreshInterceptor가 처리하므로 여기서는 제외
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
