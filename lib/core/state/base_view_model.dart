import 'package:flutter/foundation.dart';
import 'dart:async';
import '../error/exceptions.dart';
import '../error/error_handler.dart';
import '../error/error_logger.dart';

/// 작업 상태를 나타내는 열거형
enum OperationStatus { idle, loading, success, error, cancelled }

/// 비동기 작업 결과
class OperationResult<T> {
  final bool isSuccess;
  final T? data;
  final AppException? error;
  final bool wasCancelled;

  const OperationResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.wasCancelled = false,
  });

  factory OperationResult.success(T data) {
    return OperationResult._(isSuccess: true, data: data);
  }

  factory OperationResult.failure(AppException error) {
    return OperationResult._(isSuccess: false, error: error);
  }

  factory OperationResult.cancelled() {
    return OperationResult._(isSuccess: false, wasCancelled: true);
  }
}

/// 모든 ViewModel의 기본 클래스 (개선된 버전)
/// 공통 상태 관리 로직과 에러 처리를 제공
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;
  AppException? _error;
  String? _successMessage;
  OperationStatus _operationStatus = OperationStatus.idle;

  // 진행 중인 작업들 관리
  final Set<String> _ongoingOperations = <String>{};
  final Map<String, CancelToken> _cancellationTokens = <String, CancelToken>{};

  // ========================= 상태 Getters =========================

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 에러 상태
  AppException? get error => _error;

  /// 에러 발생 여부
  bool get hasError => _error != null;

  /// 성공 메시지
  String? get successMessage => _successMessage;

  /// 성공 메시지 존재 여부
  bool get hasSuccessMessage => _successMessage != null;

  /// ViewModel 해제 여부
  bool get isDisposed => _isDisposed;

  /// 현재 작업 상태
  OperationStatus get operationStatus => _operationStatus;

  /// 특정 작업이 진행 중인지 확인
  bool isOperationInProgress(String operationId) {
    return _ongoingOperations.contains(operationId);
  }

  /// 진행 중인 작업 목록
  Set<String> get ongoingOperations => Set<String>.from(_ongoingOperations);

  // ========================= 상태 관리 메서드 =========================

  /// 로딩 상태 설정
  /// [loading] - 로딩 상태
  /// [operationId] - 특정 작업 ID (선택사항)
  /// [notify] - 리스너 알림 여부 (기본값: true)
  @protected
  void setLoading(bool loading, {String? operationId, bool notify = true}) {
    if (_isDisposed) return;

    if (operationId != null) {
      if (loading) {
        _ongoingOperations.add(operationId);
      } else {
        _ongoingOperations.remove(operationId);
      }
    }

    final wasLoading = _isLoading;
    _isLoading = loading || _ongoingOperations.isNotEmpty;

    // 상태가 실제로 변경되었을 때만 알림
    if (wasLoading != _isLoading && notify) {
      _updateOperationStatus();
      notifyListeners();
    }
  }

  /// 에러 설정
  /// [error] - 에러 객체
  /// [operationId] - 작업 ID (선택사항)
  /// [logError] - 에러 로깅 여부 (기본값: true)
  /// [notify] - 리스너 알림 여부 (기본값: true)
  @protected
  void setError(
      dynamic error, {
        String? operationId,
        bool logError = true,
        bool notify = true,
        Map<String, dynamic>? context,
      }) {
    if (_isDisposed) return;

    _error = ErrorHandler.handleError(
      error,
      context: ErrorContext(
        operation: operationId ?? 'unknown',
        screen: runtimeType.toString(),
        additionalData: context,
      ),
    );

    _successMessage = null; // 에러 발생 시 성공 메시지 초기화
    _operationStatus = OperationStatus.error;

    // 에러 통계 기록
    ErrorHandler.recordErrorOccurrence(_error!);

    if (logError) {
      ErrorLogger.logError(
        _error,
        context: {
          'viewmodel': runtimeType.toString(),
          'operation_id': operationId,
          ...?context,
        },
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  /// 성공 메시지 설정
  /// [message] - 성공 메시지
  /// [notify] - 리스너 알림 여부 (기본값: true)
  @protected
  void setSuccessMessage(String message, {bool notify = true}) {
    if (_isDisposed) return;

    _successMessage = message;
    _error = null; // 성공 메시지 설정 시 에러 초기화
    _operationStatus = OperationStatus.success;

    if (notify) {
      notifyListeners();
    }
  }

  /// 에러 및 성공 메시지 초기화
  @protected
  void clearMessages({bool notify = true}) {
    if (_isDisposed) return;

    _error = null;
    _successMessage = null;

    if (notify) {
      notifyListeners();
    }
  }

  /// 전체 상태 초기화
  @protected
  void resetState({bool notify = true}) {
    if (_isDisposed) return;

    _isLoading = false;
    _error = null;
    _successMessage = null;
    _operationStatus = OperationStatus.idle;
    _ongoingOperations.clear();
    _cancelAllOperations();

    if (notify) {
      notifyListeners();
    }
  }

  // ========================= 비동기 작업 관리 =========================

  /// 비동기 작업 실행 헬퍼 (개선된 버전)
  /// [operation] - 실행할 비동기 작업
  /// [operationId] - 작업 고유 ID
  /// [showLoading] - 로딩 상태 표시 여부 (기본값: true)
  /// [clearPreviousError] - 이전 에러 초기화 여부 (기본값: true)
  /// [successMessage] - 성공 시 표시할 메시지 (선택사항)
  /// [timeout] - 작업 타임아웃 (선택사항)
  /// [onSuccess] - 성공 콜백 (선택사항)
  /// [onError] - 에러 콜백 (선택사항)
  @protected
  Future<OperationResult<T>> executeOperation<T>(
      Future<T> Function(CancelToken cancelToken) operation, {
        required String operationId,
        bool showLoading = true,
        bool clearPreviousError = true,
        String? successMessage,
        Duration? timeout,
        Function(T result)? onSuccess,
        Function(AppException error)? onError,
      }) async {
    if (_isDisposed) {
      return OperationResult.cancelled();
    }

    // 중복 실행 방지
    if (_ongoingOperations.contains(operationId)) {
      return OperationResult.failure(
        AppException('Operation $operationId is already in progress'),
      );
    }

    final cancelToken = CancelToken();
    _cancellationTokens[operationId] = cancelToken;

    try {
      if (clearPreviousError) {
        clearMessages(notify: false);
      }

      if (showLoading) {
        setLoading(true, operationId: operationId, notify: true);
      }

      _operationStatus = OperationStatus.loading;

      // 타임아웃 적용
      final Future<T> operationFuture = operation(cancelToken);
      final Future<T> timedOperation = timeout != null
          ? operationFuture.timeout(timeout)
          : operationFuture;

      final result = await timedOperation;

      // 취소되었는지 확인
      if (cancelToken.isCancelled) {
        return OperationResult.cancelled();
      }

      if (successMessage != null) {
        setSuccessMessage(successMessage, notify: false);
      } else {
        _operationStatus = OperationStatus.success;
      }

      if (onSuccess != null) {
        onSuccess(result);
      }

      return OperationResult.success(result);

    } catch (error) {
      if (cancelToken.isCancelled) {
        _operationStatus = OperationStatus.cancelled;
        return OperationResult.cancelled();
      }

      final appException = ErrorHandler.handleError(
        error,
        context: ErrorContext(
          operation: operationId,
          screen: runtimeType.toString(),
        ),
      );

      setError(appException, operationId: operationId, notify: false);

      if (onError != null) {
        onError(appException);
      }

      return OperationResult.failure(appException);

    } finally {
      if (showLoading) {
        setLoading(false, operationId: operationId, notify: true);
      } else {
        notifyListeners();
      }

      _cancellationTokens.remove(operationId);
    }
  }

  /// 여러 작업을 병렬로 실행
  /// [operations] - 실행할 작업들의 맵 (작업ID -> 작업함수)
  /// [showLoading] - 로딩 상태 표시 여부 (기본값: true)
  /// [timeout] - 전체 타임아웃 (선택사항)
  @protected
  Future<Map<String, OperationResult<dynamic>>> executeParallelOperations(
      Map<String, Future<dynamic> Function(CancelToken)> operations, {
        bool showLoading = true,
        Duration? timeout,
      }) async {
    if (_isDisposed) return {};

    final results = <String, OperationResult<dynamic>>{};

    try {
      clearMessages(notify: false);

      if (showLoading) {
        setLoading(true, notify: true);
      }

      // 모든 작업을 병렬로 실행
      final futures = operations.entries.map((entry) async {
        final result = await executeOperation(
          entry.value,
          operationId: entry.key,
          showLoading: false,
          clearPreviousError: false,
        );
        return MapEntry(entry.key, result);
      });

      final List<MapEntry<String, OperationResult<dynamic>>> completedTasks;

      if (timeout != null) {
        completedTasks = await Future.wait(futures).timeout(timeout);
      } else {
        completedTasks = await Future.wait(futures);
      }

      for (final entry in completedTasks) {
        results[entry.key] = entry.value;
      }

      return results;

    } catch (e) {
      setError(e, notify: false);
      return results;
    } finally {
      if (showLoading) {
        setLoading(false, notify: true);
      }
    }
  }

  /// 특정 작업 취소
  @protected
  void cancelOperation(String operationId) {
    final cancelToken = _cancellationTokens[operationId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel();
      _ongoingOperations.remove(operationId);
      setLoading(false, operationId: operationId);
    }
  }

  /// 모든 진행 중인 작업 취소
  @protected
  void cancelAllOperations() {
    for (final token in _cancellationTokens.values) {
      if (!token.isCancelled) {
        token.cancel();
      }
    }
    _cancellationTokens.clear();
    _ongoingOperations.clear();
    setLoading(false);
  }

  /// 작업 상태 업데이트
  void _updateOperationStatus() {
    if (_isLoading) {
      _operationStatus = OperationStatus.loading;
    } else if (_error != null) {
      _operationStatus = OperationStatus.error;
    } else if (_successMessage != null) {
      _operationStatus = OperationStatus.success;
    } else {
      _operationStatus = OperationStatus.idle;
    }
  }

  // ========================= 라이프사이클 관리 =========================

  /// ViewModel 초기화 (서브클래스에서 오버라이드)
  @protected
  @mustCallSuper
  void initialize() {
    // 서브클래스에서 구현
    debugPrint('${runtimeType} initialized');
  }

  /// 리소스 정리 (서브클래스에서 오버라이드)
  @protected
  @mustCallSuper
  void cleanup() {
    // 서브클래스에서 구현
    debugPrint('${runtimeType} cleaned up');
  }

  /// ViewModel 해제
  @override
  @mustCallSuper
  void dispose() {
    _isDisposed = true;
    cancelAllOperations();
    cleanup();
    super.dispose();
  }

  /// 안전한 notifyListeners 호출
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// 디버그 정보 출력
  @protected
  void debugPrintState() {
    if (kDebugMode) {
      debugPrint('''
ViewModel State (${runtimeType}):
- Loading: $_isLoading
- Error: $_error
- Success Message: $_successMessage
- Operation Status: $_operationStatus
- Ongoing Operations: $_ongoingOperations
- Is Disposed: $_isDisposed
''');
    }
  }
}

/// 작업 취소를 위한 토큰
class CancelToken {
  bool _isCancelled = false;
  String? _reason;

  bool get isCancelled => _isCancelled;
  String? get reason => _reason;

  void cancel([String? reason]) {
    _isCancelled = true;
    _reason = reason;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancelException(
        _reason ?? 'Operation was cancelled',
        code: 'operation_cancelled',
      );
    }
  }
}