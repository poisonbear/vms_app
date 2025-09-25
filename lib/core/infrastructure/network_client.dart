import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 통합 네트워크 클라이언트
class NetworkClient {
  static NetworkClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _tokenRefreshController = StreamController<bool>.broadcast();
  final Map<String, String> _endpointCache = {};

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
      _AuthInterceptor(this),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
      _RetryInterceptor(),
    ]);
  }

  static Options createOptions({
    Duration? timeout,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      receiveTimeout: timeout ?? AppDurations.seconds30,
      sendTimeout: timeout ?? AppDurations.seconds30,
      headers: headers,
    );
  }

  Future<void> saveCredentials(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.d('Credentials saved: $key');
    } catch (e) {
      AppLogger.e('Failed to save credentials: $e');
      throw SecurityException('자격 증명 저장 실패', originalError: e);
    }
  }

  Future<String?> getCredentials(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.e('Failed to read credentials: $e');
      return null;
    }
  }

  Future<void> deleteCredentials(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('Credentials deleted: $key');
    } catch (e) {
      AppLogger.e('Failed to delete credentials: $e');
    }
  }

  Future<void> clearAllCredentials() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('All credentials cleared');
    } catch (e) {
      AppLogger.e('Failed to clear all credentials: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    return ErrorHandler.handleError(e);
  }

  void dispose() {
    _tokenRefreshController.close();
  }
}

/// DioRequest 클래스 - 하위 호환성 유지
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
  }) {
    return NetworkClient.createOptions(
      timeout: timeout,
      headers: headers,
    );
  }

  Future<void> saveToken(String token) async {
    await _networkClient.saveCredentials('auth_token', token);
  }

  Future<String?> getToken() async {
    return await _networkClient.getCredentials('auth_token');
  }

  Future<void> deleteToken() async {
    await _networkClient.deleteCredentials('auth_token');
  }
}

/// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  final NetworkClient client;

  _AuthInterceptor(this.client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await client.getCredentials('auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      AppLogger.w('Token expired, attempting refresh...');
      // TODO: Implement token refresh logic
    }
    handler.next(err);
  }
}

/// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    handler.next(err);
  }
}

/// Error Interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = ErrorHandler.handleError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }
}

/// Retry Interceptor
class _RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode ?? 0;
    final isRetryable = (statusCode >= 500) ||
        (statusCode == 0) ||
        (err.type == DioExceptionType.connectionTimeout);

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (isRetryable && retryCount < maxRetries) {
      AppLogger.w('Retrying request... Attempt ${retryCount + 1}/$maxRetries');

      await Future.delayed(retryDelay * (retryCount + 1));

      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await NetworkClient().dio.request(
          options.path,
          options: Options(
            method: options.method,
            headers: options.headers,
          ),
          data: options.data,
          queryParameters: options.queryParameters,
        );

        return handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}

/// Navigation 관련 유틸리티 메서드들
PageRouteBuilder createSlideTransition({
  required Widget page,
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

/// Warning 팝업 메서드들
void warningPop(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('경고'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}

void warningPopdetail(
    BuildContext context, {
      required String title,
      required String message,
      VoidCallback? onConfirm,
    }) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}