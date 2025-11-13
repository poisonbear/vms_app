import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// Provider 기본 클래스 - 메모리 안전 및 에러 처리
abstract class BaseProvider extends ChangeNotifier {
  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 에러 상태
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Dispose 상태 추적
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  // 활성 타이머 추적
  final Set<Timer> _activeTimers = {};

  // Stream subscriptions 추적
  final List<StreamSubscription> _subscriptions = [];

  /// 안전한 notifyListeners 호출
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        AppLogger.e('Error in notifyListeners: $e');
      }
    }
  }

  /// 로딩 상태 설정
  @protected
  void setLoading(bool loading) {
    if (!_isDisposed) {
      _isLoading = loading;
      safeNotifyListeners();
    }
  }

  /// 에러 메시지 설정
  @protected
  void setError(String message) {
    if (!_isDisposed) {
      _errorMessage = message;
      safeNotifyListeners();

      if (message.isNotEmpty) {
        AppLogger.e('Provider error: $message');
      }
    }
  }

  /// 에러 클리어
  @protected
  void clearError() {
    if (_errorMessage.isNotEmpty && !_isDisposed) {
      _errorMessage = '';
      safeNotifyListeners();
    }
  }

  /// 비동기 작업 실행 래퍼
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
    Function(AppException)? onError,
  }) async {
    if (_isDisposed) {
      AppLogger.w('Attempted async operation after disposal');
      return null;
    }

    try {
      if (showLoading) setLoading(true);
      clearError();

      final result = await operation();

      if (_isDisposed) {
        AppLogger.w('Operation completed after disposal');
        return null;
      }

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
    if (_isDisposed) {
      AppLogger.w('Attempted sync operation after disposal');
      return null;
    }

    try {
      return operation();
    } catch (e) {
      final appException = ErrorHandler.handleError(e);
      setError(errorMessage ?? ErrorHandler.getUserMessage(appException));
      return null;
    }
  }

  /// 반복 타이머 추가 (자동 관리)
  @protected
  Timer createTimer(Duration duration, void Function(Timer) callback) {
    if (_isDisposed) {
      throw StateError('Cannot create timer after disposal');
    }

    final timer = Timer.periodic(duration, (t) {
      if (!_isDisposed) {
        callback(t);
      } else {
        t.cancel();
        _activeTimers.remove(t);
      }
    });

    _activeTimers.add(timer);
    return timer;
  }

  /// 단일 실행 타이머 추가
  @protected
  Timer createSingleTimer(Duration duration, VoidCallback callback) {
    if (_isDisposed) {
      throw StateError('Cannot create timer after disposal');
    }

    // late 키워드로 선언 후 초기화
    late Timer timer;
    timer = Timer(duration, () {
      if (!_isDisposed) {
        callback();
      }
      // 타이머 실행 후 자동 제거
      _activeTimers.remove(timer);
    });

    _activeTimers.add(timer);
    return timer;
  }

  /// Stream subscription 추가 (자동 관리)
  @protected
  StreamSubscription<T> addSubscription<T>(
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    VoidCallback? onDone,
  }) {
    if (_isDisposed) {
      throw StateError('Cannot add subscription after disposal');
    }

    final subscription = stream.listen(
      (data) {
        if (!_isDisposed) {
          onData(data);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: false,
    );

    _subscriptions.add(subscription);
    return subscription;
  }

  /// 특정 타이머 취소
  @protected
  void cancelTimer(Timer timer) {
    timer.cancel();
    _activeTimers.remove(timer);
  }

  /// 모든 타이머 취소
  @protected
  void cancelAllTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// 특정 Stream subscription 취소
  @protected
  Future<void> cancelSubscription(StreamSubscription subscription) async {
    await subscription.cancel();
    _subscriptions.remove(subscription);
  }

  /// 모든 Stream subscriptions 취소
  @protected
  Future<void> cancelAllSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// 리소스 정리 (dispose 전 호출)
  @protected
  Future<void> cleanup() async {
    if (_isDisposed) return;

    try {
      // 모든 타이머 취소
      cancelAllTimers();

      // 모든 StreamSubscription 취소
      await cancelAllSubscriptions();

      // 상태 초기화
      _isLoading = false;
      _errorMessage = '';

      AppLogger.d('$runtimeType cleanup completed');
    } catch (e) {
      AppLogger.e('Error during cleanup: $e');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      AppLogger.w('$runtimeType already disposed');
      return;
    }

    _isDisposed = true;

    // 동기적으로 타이머 정리 (즉시 실행)
    cancelAllTimers();

    // 비동기 정리 작업
    cleanup().catchError((error) {
      AppLogger.e('Error during cleanup: $error');
    });

    super.dispose();
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    AppLogger.d('=== $runtimeType Debug Info ===');
    AppLogger.d('IsDisposed: $_isDisposed');
    AppLogger.d('IsLoading: $_isLoading');
    AppLogger.d('HasError: $hasError');
    if (hasError) {
      AppLogger.d('ErrorMessage: $_errorMessage');
    }
    AppLogger.d('Active Timers: ${_activeTimers.length}');
    AppLogger.d('Active Subscriptions: ${_subscriptions.length}');
    AppLogger.d('================================');
  }
}
