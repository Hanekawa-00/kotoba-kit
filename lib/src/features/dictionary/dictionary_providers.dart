import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/dictionary_config.dart';
import '../../data/models/dictionary_entry.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../data/services/dictionary_service.dart';

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  final repository = LocalDictionaryRepository(
    SharedPreferencesAsync(),
    DictionaryService(),
  );

  ref.onDispose(repository.dispose);
  return repository;
});

final dictionaryControllerProvider =
    AsyncNotifierProvider<DictionaryController, DictionaryState>(
      DictionaryController.new,
    );

class DictionaryController extends AsyncNotifier<DictionaryState> {
  @override
  Future<DictionaryState> build() async {
    final repository = ref.watch(dictionaryRepositoryProvider);
    return DictionaryState(
      configs: await repository.loadConfigs(),
      isSupported: repository.isSupported,
    );
  }

  Future<void> importDictionary() async {
    final current = _current;
    state = AsyncData(current.copyWith(isImporting: true, errorMessage: null));

    try {
      final repository = ref.read(dictionaryRepositoryProvider);
      final result = await repository.importDictionary();
      final configs = await repository.loadConfigs();
      final next = current.copyWith(
        configs: configs,
        isImporting: false,
        lastImportedName: result?.config.name,
      );
      state = AsyncData(next);

      if (next.query.trim().isNotEmpty) {
        await search(next.query);
      }
    } catch (error) {
      state = AsyncData(
        current.copyWith(isImporting: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> search(String query) async {
    final current = _current.copyWith(query: query, errorMessage: null);

    if (query.trim().isEmpty) {
      state = AsyncData(current.copyWith(result: DictionarySearchResult.empty));
      return;
    }

    state = AsyncData(current.copyWith(isSearching: true));

    try {
      final result = await ref
          .read(dictionaryRepositoryProvider)
          .search(current.configs, query);
      state = AsyncData(current.copyWith(result: result, isSearching: false));
    } catch (error) {
      state = AsyncData(
        current.copyWith(isSearching: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final current = _current;
    final repository = ref.read(dictionaryRepositoryProvider);
    final configs = await repository.setEnabled(current.configs, id, enabled);
    state = AsyncData(current.copyWith(configs: configs));

    if (current.query.trim().isNotEmpty) {
      await search(current.query);
    }
  }

  Future<void> deleteDictionary(DictionaryConfig config) async {
    final current = _current;

    try {
      final repository = ref.read(dictionaryRepositoryProvider);
      await repository.deleteDictionary(current.configs, config);
      final configs = await repository.loadConfigs();
      state = AsyncData(current.copyWith(configs: configs));

      if (current.query.trim().isNotEmpty) {
        await search(current.query);
      }
    } catch (error) {
      state = AsyncData(current.copyWith(errorMessage: error.toString()));
    }
  }

  void clearImportNotice() {
    state = AsyncData(_current.copyWith(lastImportedName: ''));
  }

  DictionaryState get _current =>
      state.asData?.value ?? const DictionaryState();
}

class DictionaryState {
  const DictionaryState({
    this.configs = const [],
    this.result = DictionarySearchResult.empty,
    this.query = '',
    this.isSupported = true,
    this.isImporting = false,
    this.isSearching = false,
    this.errorMessage,
    this.lastImportedName,
  });

  final List<DictionaryConfig> configs;
  final DictionarySearchResult result;
  final String query;
  final bool isSupported;
  final bool isImporting;
  final bool isSearching;
  final String? errorMessage;
  final String? lastImportedName;

  bool get hasEnabledDictionary => configs.any((config) => config.enabled);

  DictionaryState copyWith({
    List<DictionaryConfig>? configs,
    DictionarySearchResult? result,
    String? query,
    bool? isSupported,
    bool? isImporting,
    bool? isSearching,
    String? errorMessage,
    String? lastImportedName,
  }) {
    return DictionaryState(
      configs: configs ?? this.configs,
      result: result ?? this.result,
      query: query ?? this.query,
      isSupported: isSupported ?? this.isSupported,
      isImporting: isImporting ?? this.isImporting,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      lastImportedName: lastImportedName ?? this.lastImportedName,
    );
  }
}
