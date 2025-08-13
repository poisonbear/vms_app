// lib/core/state/base_view_model.dart
import 'package:flutter/foundation.dart';
import '../error/exceptions.dart';
import '../error/error_handler.dart';
import '../error/error_logger.dart';

/// 모든 ViewModel의 기본 클래스
/// 공통 상태 관리 로직과 에러 처리를 제공
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;
  AppException? _error;
  String? _successMessage;

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

  // ========================= 상태 관리 메서드 =========================

  /// 로딩 상태 설정
  /// [loading] - 로딩 상태
  /// [notifyListeners] - 리스너 알림 여부 (기본값: true)
  @protected
  void setLoading(bool loading, {bool notify = true}) {
    if (_isDisposed) return;

    _isLoading = loading;
    if (notify) {
      notifyListeners();
    }
  }

  /// 에러 설정
  /// [error] - 에러 객체
  /// [logError] - 에러 로깅 여부 (기본값: true)
  /// [notifyListeners] - 리스너 알림 여부 (기본값: true)
  @protected
  void setError(
      dynamic error, {
        bool logError = true,
        bool notify = true,
        Map<String, dynamic>? context,
      }) {
    if (_isDisposed) return;

    _error = ErrorHandler.handleError(error);
    _successMessage = null; // 에러 발생 시 성공 메시지 초기화

    if (logError) {
      ErrorLogger.logError(
        _error,
        context: {
          'viewmodel': runtimeType.toString(),
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
  /// [notifyListeners] - 리스너 알림 여부 (기본값: true)
  @protected
  void setSuccessMessage(String message, {bool notify = true}) {
    if (_isDisposed) return;

    _successMessage = message;
    _error = null; // 성공 메시지 설정 시 에러 초기화

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

    if (notify) {
      notifyListeners();
    }
  }

  // ========================= 비동기 작업 관리 =========================

  /// 비동기 작업 실행 헬퍼
  /// [operation] - 실행할 비동기 작업
  /// [showLoading] - 로딩 상태 표시 여부 (기본값: true)
  /// [clearPreviousError] - 이전 에러 초기화 여부 (기본값: true)
  /// [successMessage] - 성공 시 표시할 메시지 (선택사항)
  /// [onSuccess] - 성공 콜백 (선택사항)
  /// [onError] - 에러 콜백 (선택사항)
  @protected
  Future<T?> executeOperation<T>(
      Future<T> Function() operation, {
        bool showLoading = true,
        bool clearPreviousError = true,
        String? successMessage,
        Function(T result)? onSuccess,
        Function(dynamic error)? onError,
      }) async {
    if (_isDisposed) return null;

    try {
      if (clearPreviousError) {
        clearMessages(notify: false);
      }

      if (showLoading) {
        setLoading(true, notify: true);
      }

      final result = await operation();

      if (successMessage != null) {
        setSuccessMessage(successMessage, notify: false);
      }

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;

    } catch (error) {
      setError(error, notify: false);

      if (onError != null) {
        onError(error);
      }

      return null;
    } finally {
      if (showLoading) {
        setLoading(false, notify: true);
      } else {
        notifyListeners();
      }
    }
  }

  /// 다중 비동기 작업 실행
  /// [operations] - 실행할 비동기 작업들
  /// [showLoading] - 로딩 상태 표시 여부 (기본값: true)
  /// [stopOnFirstError] - 첫 번째 에러에서 중단 여부 (기본값: true)
  @protected
  Future<List<T?>> executeMultipleOperations<T>(
      List<Future<T> Function()> operations, {
        bool showLoading = true,
        bool stopOnFirstError = true,
      }) async {
    if (_isDisposed) return [];

    final results = <T?>[];

    try {
      clearMessages(notify: false);

      if (showLoading) {
        setLoading(true, notify: true);
      }

      for (final operation in operations) {
        try {
          final result = await operation();
          results.add(result);
        } catch (error) {
          results.add(null);

          if (stopOnFirstError) {
            setError(error, notify: false);
            break;
          }
        }
      }

      return results;

    } finally {
      if (showLoading) {
        setLoading(false, notify: true);
      }
    }
  }

  // ========================= 라이프사이클 관리 =========================

  /// ViewModel 초기화 (서브클래스에서 오버라이드)
  @protected
  @mustCallSuper
  void initialize() {
    // 서브클래스에서 구현
  }

  /// ViewModel 해제
  @override
  @mustCallSuper
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// 안전한 notifyListeners 호출
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}

// lib/core/state/loading_state.dart
/// 로딩 상태를 나타내는 열거형
enum LoadingState {
  /// 초기 상태
  initial,
  /// 로딩 중
  loading,
  /// 성공
  success,
  /// 에러
  error,
  /// 새로고침 중
  refreshing,
}

/// 로딩 상태 확장 메서드
extension LoadingStateExtension on LoadingState {
  /// 로딩 중인지 확인
  bool get isLoading => this == LoadingState.loading || this == LoadingState.refreshing;

  /// 성공 상태인지 확인
  bool get isSuccess => this == LoadingState.success;

  /// 에러 상태인지 확인
  bool get isError => this == LoadingState.error;

  /// 초기 상태인지 확인
  bool get isInitial => this == LoadingState.initial;

  /// 새로고침 중인지 확인
  bool get isRefreshing => this == LoadingState.refreshing;
}

// lib/core/state/paginated_view_model.dart
/// 페이지네이션을 지원하는 ViewModel 기본 클래스
abstract class PaginatedViewModel<T> extends BaseViewModel {
  List<T> _items = [];
  int _currentPage = 1;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;

  /// 현재 아이템 목록
  List<T> get items => List.unmodifiable(_items);

  /// 현재 페이지
  int get currentPage => _currentPage;

  /// 더 많은 아이템 존재 여부
  bool get hasMoreItems => _hasMoreItems;

  /// 추가 로딩 상태
  bool get isLoadingMore => _isLoadingMore;

  /// 전체 아이템 개수
  int get itemCount => _items.length;

  /// 빈 리스트 여부
  bool get isEmpty => _items.isEmpty;

  // ========================= 추상 메서드 =========================

  /// 페이지별 데이터 로드 (서브클래스에서 구현)
  @protected
  Future<List<T>> loadPage(int page);

  // ========================= 페이지네이션 관리 =========================

  /// 첫 페이지 로드
  Future<void> loadFirstPage() async {
    await executeOperation(
          () async {
        _currentPage = 1;
        _hasMoreItems = true;

        final newItems = await loadPage(_currentPage);

        _items.clear();
        _items.addAll(newItems);

        // 페이지 크기보다 적으면 더 이상 페이지가 없음
        if (newItems.length < getPageSize()) {
          _hasMoreItems = false;
        }

        return _items;
      },
      successMessage: null,
    );
  }

  /// 다음 페이지 로드
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMoreItems || isLoading) return;

    try {
      _isLoadingMore = true;
      safeNotifyListeners();

      final nextPage = _currentPage + 1;
      final newItems = await loadPage(nextPage);

      if (newItems.isNotEmpty) {
        _items.addAll(newItems);
        _currentPage = nextPage;

        // 페이지 크기보다 적으면 더 이상 페이지가 없음
        if (newItems.length < getPageSize()) {
          _hasMoreItems = false;
        }
      } else {
        _hasMoreItems = false;
      }

    } catch (error) {
      setError(error, notify: false);
    } finally {
      _isLoadingMore = false;
      safeNotifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    clearMessages();
    await loadFirstPage();
  }

  /// 특정 아이템 추가
  void addItem(T item, {bool notify = true}) {
    _items.add(item);
    if (notify) {
      safeNotifyListeners();
    }
  }

  /// 특정 인덱스에 아이템 삽입
  void insertItem(int index, T item, {bool notify = true}) {
    if (index >= 0 && index <= _items.length) {
      _items.insert(index, item);
      if (notify) {
        safeNotifyListeners();
      }
    }
  }

  /// 특정 아이템 제거
  bool removeItem(T item, {bool notify = true}) {
    final removed = _items.remove(item);
    if (removed && notify) {
      safeNotifyListeners();
    }
    return removed;
  }

  /// 특정 인덱스의 아이템 제거
  T? removeItemAt(int index, {bool notify = true}) {
    if (index >= 0 && index < _items.length) {
      final item = _items.removeAt(index);
      if (notify) {
        safeNotifyListeners();
      }
      return item;
    }
    return null;
  }

  /// 특정 아이템 업데이트
  void updateItem(int index, T item, {bool notify = true}) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      if (notify) {
        safeNotifyListeners();
      }
    }
  }

  /// 조건에 맞는 아이템 찾기
  T? findItem(bool Function(T) predicate) {
    try {
      return _items.firstWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  /// 조건에 맞는 아이템 인덱스 찾기
  int findItemIndex(bool Function(T) predicate) {
    for (int i = 0; i < _items.length; i++) {
      if (predicate(_items[i])) {
        return i;
      }
    }
    return -1;
  }

  /// 전체 목록 초기화
  void clearItems({bool notify = true}) {
    _items.clear();
    _currentPage = 1;
    _hasMoreItems = true;
    _isLoadingMore = false;

    if (notify) {
      safeNotifyListeners();
    }
  }

  /// 페이지 크기 반환 (서브클래스에서 오버라이드 가능)
  @protected
  int getPageSize() => 20;

  @override
  void dispose() {
    _items.clear();
    super.dispose();
  }
}

// lib/core/state/cached_view_model.dart
import '../network/request_cache.dart';

/// 캐시 기능이 있는 ViewModel 기본 클래스
abstract class CachedViewModel<T> extends BaseViewModel {
  final RequestCache _cache = RequestCache();
  T? _cachedData;
  Duration _cacheDuration = const Duration(minutes: 5);

  /// 캐시된 데이터
  T? get cachedData => _cachedData;

  /// 캐시 데이터 존재 여부
  bool get hasCachedData => _cachedData != null;

  /// 캐시 지속 시간 설정
  @protected
  void setCacheDuration(Duration duration) {
    _cacheDuration = duration;
  }

  /// 캐시 키 생성 (서브클래스에서 구현)
  @protected
  String getCacheKey();

  /// 데이터 로드 (서브클래스에서 구현)
  @protected
  Future<T> loadData();

  /// 캐시된 데이터 로드
  Future<void> loadCachedData() async {
    final cacheKey = getCacheKey();
    final cached = _cache.get<T>(cacheKey, cacheDuration: _cacheDuration);

    if (cached != null) {
      _cachedData = cached;
      safeNotifyListeners();
    }
  }

  /// 데이터 로드 (캐시 우선)
  Future<void> loadWithCache({bool forceRefresh = false}) async {
    final cacheKey = getCacheKey();

    // 강제 새로고침이 아니고 캐시가 있으면 캐시 사용
    if (!forceRefresh) {
      final cached = _cache.get<T>(cacheKey, cacheDuration: _cacheDuration);
      if (cached != null) {
        _cachedData = cached;
        safeNotifyListeners();
        return;
      }
    }

    // 진행 중인 요청이 있는지 확인
    final ongoingRequest = _cache.getOngoingRequest(cacheKey);
    if (ongoingRequest != null) {
      try {
        _cachedData = await ongoingRequest as T;
        safeNotifyListeners();
        return;
      } catch (error) {
        setError(error);
        return;
      }
    }

    // 새로운 데이터 로드
    await executeOperation(
          () async {
        final request = loadData();
        _cache.addOngoingRequest(cacheKey, request);

        final data = await request;

        // 캐시에 저장
        _cache.set(cacheKey, data);
        _cachedData = data;

        return data;
      },
    );
  }

  /// 캐시 무효화
  void invalidateCache() {
    final cacheKey = getCacheKey();
    _cache.remove(cacheKey);
    _cachedData = null;
  }

  /// 전체 캐시 초기화
  void clearAllCache() {
    _cache.clear();
    _cachedData = null;
  }

  @override
  void dispose() {
    _cachedData = null;
    super.dispose();
  }
}