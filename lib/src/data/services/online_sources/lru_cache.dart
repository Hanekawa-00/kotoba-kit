class LRUCache<K, V> {
  LRUCache({required this.maxSize});

  final int maxSize;
  final Map<K, V> _cache = <K, V>{};

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _cache.remove(key);
    _cache[key] = value;
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void clear() => _cache.clear();

  int get length => _cache.length;
}
