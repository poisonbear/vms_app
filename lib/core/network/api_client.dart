import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API 통신을 위한 개선된 클라이언트
class ApiClient {
  static ApiClient? _instance;

  /// 싱글톤 인스턴스
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// 팩토리 생성자 (싱글톤 패턴)
  factory ApiClient() => instance;

  ApiClient._internal() {
    _initializeDio();
  }

  late final Dio _dio;

  // 설정 상수들
  static const Duration _defaultConnectTimeout = Duration(seconds: 10);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 8);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  Dio get dio => _dio;

  /// Dio 초기화
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        contentType: Headers.jsonContentType,
        connectTimeout: _defaultConnectTimeout,
        receiveTimeout: _defaultReceiveTimeout,
        headers: _getDefaultHeaders(),
      ),
    );

    // 개발 모드에서만 로깅 인터셉터 추가
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    // 재시도 인터셉터 추가
    _dio.interceptors.add(_createRetryInterceptor());
  }

  /// 기본 헤더 설정
  Map<String, String> _getDefaultHeaders() {
    return {
      'User-Agent': 'VMS-App/1.0.0',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': '100',
    };
  }

  /// 재시도 인터셉터 생성
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error) && error.requestOptions.extra['retryCount'] == null) {
          return _retryRequest(error, handler);
        }
        handler.next(error);
      },
    );
  }

  /// 재시도 가능한 에러인지 확인
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
      // 5xx 서버 에러는 재시도
        final statusCode = error.response?.statusCode;
        return statusCode != null && statusCode >= 500;
      default:
        return false;
    }
  }

  /// 요청 재시도
  Future<void> _retryRequest(DioException error, ErrorInterceptorHandler handler) async {
    final requestOptions = error.requestOptions;
    final retryCount = (requestOptions.extra['retryCount'] as int?) ?? 0;

    if (retryCount < _maxRetries) {
      // 재시도 카운트 증가
      requestOptions.extra['retryCount'] = retryCount + 1;

      // 지연 후 재시도
      await Future.delayed(_retryDelay * (retryCount + 1));

      try {
        final response = await _dio.fetch(requestOptions);
        handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          handler.next(e);
        } else {
          handler.next(error);
        }
      }
    } else {
      handler.next(error);
    }
  }

  /// GET 요청 (재시도 로직 포함)
  Future<T?> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logError('GET', path, e);
      rethrow;
    }
  }

  /// POST 요청 (재시도 로직 포함)
  Future<T?> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logError('POST', path, e);
      rethrow;
    }
  }

  /// PUT 요청 (재시도 로직 포함)
  Future<T?> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logError('PUT', path, e);
      rethrow;
    }
  }

  /// DELETE 요청 (재시도 로직 포함)
  Future<T?> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _logError('DELETE', path, e);
      rethrow;
    }
  }

  /// 타임아웃 설정
  void setTimeouts({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    _dio.options.connectTimeout = connectTimeout ?? _defaultConnectTimeout;
    _dio.options.receiveTimeout = receiveTimeout ?? _defaultReceiveTimeout;
    _dio.options.sendTimeout = sendTimeout;
  }

  /// 베이스 URL 설정
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// 헤더 설정 (기존 헤더와 병합)
  void setHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  /// 특정 헤더 제거
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// 인증 토큰 설정
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 인증 토큰 제거
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// 인터셉터 추가
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// 인터셉터 제거
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// 특정 타입의 인터셉터 모두 제거
  void removeInterceptorsByType<T extends Interceptor>() {
    _dio.interceptors.removeWhere((interceptor) => interceptor is T);
  }

  /// 모든 인터셉터 제거
  void clearInterceptors() {
    _dio.interceptors.clear();
    // 기본 인터셉터들 다시 추가
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
    _dio.interceptors.add(_createRetryInterceptor());
  }

  /// 다운로드 (진행률 콜백 포함)
  Future<Response> download(
      String urlPath,
      String savePath, {
        ProgressCallback? onReceiveProgress,
        CancelToken? cancelToken,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logError('DOWNLOAD', urlPath, e);
      rethrow;
    }
  }

  /// 업로드 (진행률 콜백 포함)
  Future<Response<T>> upload<T>(
      String path,
      FormData formData, {
        ProgressCallback? onSendProgress,
        CancelToken? cancelToken,
        Options? options,
      }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: options,
      );
    } catch (e) {
      _logError('UPLOAD', path, e);
      rethrow;
    }
  }

  /// 연결 상태 확인
  Future<bool> checkConnection({String? testUrl}) async {
    try {
      final url = testUrl ?? _dio.options.baseUrl;
      if (url.isEmpty) return false;

      final response = await _dio.head(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 요청 취소를 위한 CancelToken 생성
  CancelToken createCancelToken() {
    return CancelToken();
  }

  /// 에러 로깅 (민감한 정보 제외)
  void _logError(String method, String path, dynamic error) {
    if (kDebugMode) {
      debugPrint('[$method] Error occurred for $path: ${error.toString()}');

      if (error is DioException) {
        debugPrint('Status Code: ${error.response?.statusCode}');
        debugPrint('Response Data: ${error.response?.data}');
      }
    }
  }

  /// Dio 인스턴스 재설정 (테스트용)
  void reset() {
    _dio.close();
    _initializeDio();
  }

  /// 리소스 정리
  void dispose() {
    _dio.close();
  }
}