class RequestCache {
  static final RequestCache _instance = RequestCache._internal();
  factory RequestCache() => _instance;
  RequestCache._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, Future<dynamic>> _ongoingRequests = {};

  /// 캐시에서 데이터 가져오기
  T? get<T>(String key, {Duration? cacheDuration}) {
    final item = _cache[key];
    if (item == null) return null;

    if (cacheDuration != null) {
      final cachedAt = item['cachedAt'] as DateTime;
      if (DateTime.now().difference(cachedAt) > cacheDuration) {
        _cache.remove(key);
        return null;
      }
    }

    return item['data'] as T?;
  }

  /// 캐시에 데이터 저장
  void set<T>(String key, T data) {
    _cache[key] = {
      'data': data,
      'cachedAt': DateTime.now(),
    };
  }

  /// 캐시에서 데이터 제거
  void remove(String key) {
    _cache.remove(key);
  }

  /// 전체 캐시 초기화
  void clear() {
    _cache.clear();
    _ongoingRequests.clear();
  }

  /// 진행 중인 요청 추가
  void addOngoingRequest(String key, Future<dynamic> request) {
    _ongoingRequests[key] = request;
    request.whenComplete(() => _ongoingRequests.remove(key));
  }

  /// 진행 중인 요청 가져오기
  Future<dynamic>? getOngoingRequest(String key) {
    return _ongoingRequests[key];
  }
}