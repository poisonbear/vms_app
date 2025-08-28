import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';

/// 모든 Provider의 기본 클래스 - 개선된 버전
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isDisposed = false;

  // 진행 중인 비동기 작업 추적
  final Set<CancelableOperation> _pendingOperations = {};

  // 공통 Getter
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isDisposed => _isDisposed;

  /// 로딩 상태 설정
  @protected
  void setLoading(bool loading) {
    if (_isDisposed) return;
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 메시지 설정
  @protected
  void setError(String message) {
    if (_isDisposed) return;
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// 에러 클리어
  @protected
  void clearError() {
    if (_isDisposed) return;
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  /// 안전한 상태 업데이트
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// 비동기 작업 실행 래퍼 - 개선된 버전
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
    Function(AppException)? onError,
  }) async {
    if (_isDisposed) return null;

    final completer = Completer<T?>();
    final cancelable = CancelableOperation.fromFuture(
      _executeAsyncInternal(
        operation,
        errorMessage: errorMessage,
        showLoading: showLoading,
        onError: onError,
      ),
    );

    _pendingOperations.add(cancelable);

    try {
      final result = await cancelable.value;
      completer.complete(result);
      return result;
    } finally {
      _pendingOperations.remove(cancelable);
    }
  }

  Future<T?> _executeAsyncInternal<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
    Function(AppException)? onError,
  }) async {
    try {
      if (showLoading) {
        _isLoading = true;
        _errorMessage = '';
        safeNotifyListeners();
      }

      final result = await operation();

      if (showLoading) {
        _isLoading = false;
        safeNotifyListeners();
      }

      return result;
    } catch (e) {
      _isLoading = false;

      final appException = ErrorHandler.handleError(e);
      _errorMessage = errorMessage ?? ErrorHandler.getUserMessage(appException);

      onError?.call(appException);

      safeNotifyListeners();
      return null;
    }
  }

  /// 동기 작업 실행 래퍼
  @protected
  T? executeSafe<T>(
    T Function() operation, {
    String? errorMessage,
  }) {
    if (_isDisposed) return null;

    try {
      clearError();
      return operation();
    } catch (e) {
      final appException = ErrorHandler.handleError(e);
      _errorMessage = errorMessage ?? ErrorHandler.getUserMessage(appException);
      safeNotifyListeners();
      return null;
    }
  }

  /// Provider 리소스 정리
  @override
  void dispose() {
    _isDisposed = true;

    // 모든 진행 중인 비동기 작업 취소
    for (final operation in _pendingOperations) {
      operation.cancel();
    }
    _pendingOperations.clear();

    super.dispose();
  }
}

/// 취소 가능한 비동기 작업
class CancelableOperation<T> {
  final Future<T> _future;
  bool _isCanceled = false;

  CancelableOperation.fromFuture(this._future);

  Future<T> get value async {
    if (_isCanceled) {
      throw StateError('Operation was canceled');
    }
    return _future;
  }

  void cancel() {
    _isCanceled = true;
  }
}
