class SimpleCache {
  static final _instance = SimpleCache._();
  factory SimpleCache() => _instance;
  SimpleCache._();
  
  final Map<String, CacheEntry> _cache = {};
  
  void put(String key, dynamic data, Duration duration) {
    _cache[key] = CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );
  }
  
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }
  
  void clear() => _cache.clear();
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  CacheEntry({required this.data, required this.expiry});
  bool get isExpired => DateTime.now().isAfter(expiry);
}
