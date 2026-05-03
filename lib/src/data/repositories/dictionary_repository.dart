import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dictionary_config.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';

abstract class DictionaryRepository {
  bool get isSupported;

  Future<List<DictionaryConfig>> loadConfigs();

  Future<DictionaryImportResult?> importDictionary();

  Future<void> saveConfigs(List<DictionaryConfig> configs);

  Future<DictionarySearchResult> search(
    List<DictionaryConfig> configs,
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

  Future<void> dispose();
}

class LocalDictionaryRepository implements DictionaryRepository {
  LocalDictionaryRepository(this._preferences, this._service);

  final SharedPreferencesAsync _preferences;
  final DictionaryService _service;

  static const _configsKey = 'dictionary.configs';

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
  Future<void> dispose() {
    return _service.dispose();
  }
}
