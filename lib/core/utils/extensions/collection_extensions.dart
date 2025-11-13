// lib/core/utils/extensions/collection_extensions.dart

/// List 확장
extension ListExtension<T> on List<T> {
  /// 안전한 인덱스 접근
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// 첫 번째 요소 또는 null
  T? get firstOrNull => isEmpty ? null : first;

  /// 마지막 요소 또는 null
  T? get lastOrNull => isEmpty ? null : last;

  /// 중복 제거
  List<T> get distinct => toSet().toList();

  /// 조건에 맞는 첫 번째 요소 또는 null
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }

  /// 리스트를 청크로 나누기
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}

/// Map 확장
extension MapExtension<K, V> on Map<K, V> {
  /// 안전한 값 가져오기
  T? getAs<T>(K key) {
    final value = this[key];
    return value is T ? value : null;
  }

  /// 여러 키 제거
  void removeKeys(Iterable<K> keys) {
    for (final key in keys) {
      remove(key);
    }
  }

  /// 조건부 추가
  void addIf(bool condition, K key, V value) {
    if (condition) {
      this[key] = value;
    }
  }

  /// null이 아닌 값만 추가
  void addIfNotNull(K key, V? value) {
    if (value != null) {
      this[key] = value;
    }
  }

  /// 깊은 복사
  Map<K, V> deepCopy() {
    return Map<K, V>.from(this);
  }
}
