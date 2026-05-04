import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dictionary_config.dart';
import '../models/dictionary_entry.dart';
import '../models/online_dictionary_config.dart';
import '../services/dictionary_service.dart';
import '../services/online_sources/online_dictionary_source.dart';

abstract class DictionaryRepository {
  bool get isSupported;

  Future<List<DictionaryConfig>> loadConfigs();

  Future<DictionaryImportResult?> importDictionary();

  Future<void> saveConfigs(List<DictionaryConfig> configs);

  Future<DictionarySearchResult> search(
    List<DictionaryConfig> configs,
    String query,
  );

  Future<List<String>> suggest(List<DictionaryConfig> configs, String query);

  Future<DictionarySearchResult> searchOnline(
    OnlineDictionarySource source,
    String query,
  );

  Future<void> deleteDictionary(
    List<DictionaryConfig> configs,
    DictionaryConfig config,
  );

  Future<List<DictionaryConfig>> setEnabled(
    List<DictionaryConfig> configs,
    String id,
    bool enabled,
  );

  Future<List<OnlineDictionaryConfig>> loadOnlineConfigs();

  Future<void> saveOnlineConfigs(List<OnlineDictionaryConfig> configs);

  Future<List<String>> loadSearchHistory();

  Future<List<String>> saveSearchHistory(List<String> history);

  Future<List<OnlineDictionaryConfig>> setOnlineEnabled(
    List<OnlineDictionaryConfig> configs,
    String id,
    bool enabled,
  );

  Future<void> dispose();
}

class LocalDictionaryRepository implements DictionaryRepository {
  LocalDictionaryRepository(this._preferences, this._service);

  final SharedPreferencesAsync _preferences;
  final DictionaryService _service;

  static const _configsKey = 'dictionary.configs';
  static const _onlineConfigsKey = 'dictionary.onlineConfigs';
  static const _searchHistoryKey = 'dictionary.searchHistory';
  static const _maxSearchHistory = 30;

  @override
  bool get isSupported => _service.isSupported;

  @override
  Future<List<DictionaryConfig>> loadConfigs() async {
    final raw = await _preferences.getString(_configsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(DictionaryConfig.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DictionaryImportResult?> importDictionary() async {
    final result = await _service.importFromPicker();
    if (result == null) {
      return null;
    }

    final configs = await loadConfigs();
    await saveConfigs([...configs, result.config]);
    return result;
  }

  @override
  Future<void> saveConfigs(List<DictionaryConfig> configs) {
    final raw = jsonEncode(configs.map((config) => config.toJson()).toList());
    return _preferences.setString(_configsKey, raw);
  }

  @override
  Future<DictionarySearchResult> search(
    List<DictionaryConfig> configs,
    String query,
  ) {
    return _service.search(configs, query);
  }

  @override
  Future<List<String>> suggest(List<DictionaryConfig> configs, String query) {
    return _service.suggest(configs, query);
  }

  @override
  Future<void> deleteDictionary(
    List<DictionaryConfig> configs,
    DictionaryConfig config,
  ) async {
    await _service.deleteDictionaryFiles(config);
    await saveConfigs(
      configs.where((item) => item.id != config.id).toList(growable: false),
    );
  }

  @override
  Future<List<DictionaryConfig>> setEnabled(
    List<DictionaryConfig> configs,
    String id,
    bool enabled,
  ) async {
    final next = [
      for (final config in configs)
        if (config.id == id) config.copyWith(enabled: enabled) else config,
    ];
    await saveConfigs(next);
    return next;
  }

  @override
  Future<DictionarySearchResult> searchOnline(
    OnlineDictionarySource source,
    String query,
  ) {
    return source.search(query);
  }

  @override
  Future<List<OnlineDictionaryConfig>> loadOnlineConfigs() async {
    final raw = await _preferences.getString(_onlineConfigsKey);
    List<OnlineDictionaryConfig> saved;
    if (raw == null || raw.isEmpty) {
      saved = const [];
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      saved = decoded
          .cast<Map<String, Object?>>()
          .map(OnlineDictionaryConfig.fromJson)
          .toList(growable: false);
    }

    final savedMap = {for (final c in saved) c.id: c};
    final sources = [weblioSourceConfig, jishoSourceConfig];

    final merged = <OnlineDictionaryConfig>[];
    for (final source in sources) {
      final existing = savedMap[source.id];
      merged.add(
        existing ??
            OnlineDictionaryConfig(
              id: source.id,
              name: source.name,
              enabled: true,
              baseUrl: source.baseUrl,
            ),
      );
    }

    return merged;
  }

  @override
  Future<void> saveOnlineConfigs(List<OnlineDictionaryConfig> configs) {
    final raw = jsonEncode(configs.map((c) => c.toJson()).toList());
    return _preferences.setString(_onlineConfigsKey, raw);
  }

  @override
  Future<List<OnlineDictionaryConfig>> setOnlineEnabled(
    List<OnlineDictionaryConfig> configs,
    String id,
    bool enabled,
  ) async {
    final next = [
      for (final c in configs)
        if (c.id == id) c.copyWith(enabled: enabled) else c,
    ];
    await saveOnlineConfigs(next);
    return next;
  }

  @override
  Future<List<String>> loadSearchHistory() async {
    final raw = await _preferences.getString(_searchHistoryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .take(_maxSearchHistory)
        .toList(growable: false);
  }

  @override
  Future<List<String>> saveSearchHistory(List<String> history) async {
    final normalized = normalizeSearchHistory(
      history,
      maxItems: _maxSearchHistory,
    );
    final raw = jsonEncode(normalized);
    await _preferences.setString(_searchHistoryKey, raw);
    return normalized;
  }

  @override
  Future<void> dispose() {
    return _service.dispose();
  }
}

List<String> normalizeSearchHistory(
  Iterable<String> history, {
  int maxItems = 30,
}) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final item in history) {
    final trimmed = item.trim();
    final key = trimmed.toLowerCase();
    if (trimmed.isEmpty || seen.contains(key)) {
      continue;
    }

    normalized.add(trimmed);
    seen.add(key);
    if (normalized.length >= maxItems) {
      break;
    }
  }

  return normalized;
}

class _SourceMeta {
  final String id;
  final String name;
  final String baseUrl;

  const _SourceMeta({
    required this.id,
    required this.name,
    required this.baseUrl,
  });
}

const weblioSourceConfig = _SourceMeta(
  id: 'weblio',
  name: 'Weblio',
  baseUrl: 'https://www.weblio.jp',
);
const jishoSourceConfig = _SourceMeta(
  id: 'jisho',
  name: 'Jisho',
  baseUrl: 'https://jisho.org',
);
