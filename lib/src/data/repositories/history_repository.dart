import 'package:hive_ce/hive_ce.dart';

import '../../features/practice/models/history_item.dart';

class HistoryRepository {
  HistoryRepository(this._box);

  HistoryRepository.empty() : _box = null;

  final Box<HistoryItem>? _box;

  List<HistoryItem> loadAll() {
    if (_box == null) return [];
    return _box.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<HistoryItem> loadByMode(String gameMode) {
    return loadAll().where((h) => h.gameMode == gameMode).toList(growable: false);
  }

  Future<void> addItem(HistoryItem item) async {
    if (_box == null) return;
    await _box!.put(item.id, item);
    // Cap at 100 entries
    final all = _box.values.toList();
    if (all.length > 100) {
      all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toRemove = all.sublist(0, all.length - 100);
      if (_box != null) await _box!.deleteAll(toRemove.map((e) => e.id));
    }
  }

  Future<void> deleteItem(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
  }

  Future<void> clear() async {
    if (_box == null) return;
    await _box!.clear();
  }
}
