import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';

/// 취소 가능한 비동기 작업을 위한 간단한 구현
class CancelableOperation<T> {
  final Future<T> _future;
  bool _isCanceled = false;
  
  CancelableOperation.fromFuture(this._future);
  
  Future<T> get value => _future;
  bool get isCanceled => _isCanceled;
  
  void cancel() {
    _isCanceled = true;
  }
}

/// 모든 Provider의 기본 클래스 - 메모리 누수 방지 개선
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isDisposed = false;
  
  // 진행 중인 비동기 작업 추적
  final Set<CancelableOperation> _pendingOperations = {};
  
  // Timer 관리
  final Set<Timer> _activeTimers = {};
  
  // StreamSubscription 관리  
  final List<StreamSubscription> _subscriptions = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isDisposed => _isDisposed;

  @protected
  void setLoading(bool loading) {
    if (_isDisposed) return;
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  @protected
  void setError(String message) {
    if (_isDisposed) return;
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  @protected
  void clearError() {
    if (_isDisposed) return;
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Timer 추가 및 관리
  @protected
  Timer addTimer(Duration duration, void Function() callback) {
    late Timer timer;
    timer = Timer(duration, () {
      if (!_isDisposed) {
        callback();
        _activeTimers.remove(timer);
      }
    });
    _activeTimers.add(timer);
    return timer;
  }

  /// StreamSubscription 추가 및 관리
  @protected
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
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
      if (showLoading) setLoading(true);
      clearError();
      
      final result = await operation();
      
      if (showLoading) setLoading(false);
      return result;
    } catch (e) {
      if (_isDisposed) return null;
      
      setLoading(false);
      final appException = ErrorHandler.handleError(e);
      setError(errorMessage ?? ErrorHandler.getUserMessage(appException));
      
      onError?.call(appException);
      return null;
    }
  }

  /// 동기 작업 실행 래퍼
  @protected
  T? executeSafe<T>(
    T Function() operation, {
    String? errorMessage,
  }) {
    try {
      return operation();
    } catch (e) {
      final appException = ErrorHandler.handleError(e);
      setError(errorMessage ?? ErrorHandler.getUserMessage(appException));
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // 모든 비동기 작업 취소
    for (final operation in _pendingOperations) {
      operation.cancel();
    }
    _pendingOperations.clear();
    
    // 모든 타이머 취소
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    
    // 모든 StreamSubscription 취소
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    super.dispose();
  }
}
