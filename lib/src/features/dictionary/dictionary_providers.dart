import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/dictionary_config.dart';
import '../../data/models/dictionary_entry.dart';
import '../../data/models/online_dictionary_config.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../data/services/dictionary_service.dart';
import '../../data/services/online_sources/online_dictionary_source.dart';
import '../../data/services/online_sources/online_source_providers.dart';

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
  Timer? _suggestionDebounce;
  int _searchGeneration = 0;
  int _suggestionGeneration = 0;

  @override
  Future<DictionaryState> build() async {
    ref.onDispose(() {
      _suggestionDebounce?.cancel();
    });

    final repository = ref.watch(dictionaryRepositoryProvider);
    return DictionaryState(
      configs: await repository.loadConfigs(),
      onlineConfigs: await repository.loadOnlineConfigs(),
      searchHistory: await repository.loadSearchHistory(),
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
    final generation = ++_searchGeneration;
    final current = _current.copyWith(
      query: query,
      errorMessage: null,
      selectedSourceIndex: 0,
      selectedEntryIndex: 0,
    );

    if (query.trim().isEmpty) {
      state = AsyncData(current.copyWith(result: DictionarySearchResult.empty));
      return;
    }

    state = AsyncData(current.copyWith(isSearching: true));

    try {
      final repository = ref.read(dictionaryRepositoryProvider);

      // Run local search
      final localResult = await repository.search(current.configs, query);

      // Run online searches in parallel for enabled sources
      final sources = ref.read(onlineSourcesProvider);
      final onlineFutures = <Future<DictionarySearchResult>>[];

      for (final source in sources) {
        final onlineConfig = current.onlineConfigs
            .where((c) => c.id == source.id && c.enabled)
            .firstOrNull;
        if (onlineConfig != null) {
          onlineFutures.add(_searchOnlineSource(repository, source, query));
        }
      }

      final onlineResults = await Future.wait(onlineFutures);

      if (generation != _searchGeneration) {
        return;
      }

      // Merge results
      final allEntries = [...localResult.entries];
      final allSuggestions = {...localResult.suggestions};
      final sourceErrors = <String, String>{...localResult.sourceErrors};

      for (final result in onlineResults) {
        allEntries.addAll(result.entries);
        allSuggestions.addAll(result.suggestions);
        sourceErrors.addAll(result.sourceErrors);
      }

      final searchHistory = await repository.saveSearchHistory([
        query,
        ...current.searchHistory,
      ]);

      if (generation != _searchGeneration) {
        return;
      }

      final latest = _current;
      state = AsyncData(
        latest.copyWith(
          query: query,
          result: DictionarySearchResult(
            query: query,
            entries: allEntries,
            suggestions: allSuggestions.take(12).toList(growable: false),
            sourceErrors: sourceErrors,
          ),
          searchHistory: searchHistory,
          draftSuggestions: combineLookupSuggestions(
            history: searchHistory,
            localSuggestions: allSuggestions,
            query: query,
          ),
          isSearching: false,
          errorMessage: null,
          selectedSourceIndex: 0,
          selectedEntryIndex: 0,
        ),
      );
    } catch (error) {
      if (generation != _searchGeneration) {
        return;
      }
      state = AsyncData(
        _current.copyWith(isSearching: false, errorMessage: error.toString()),
      );
    }
  }

  void updateDraft(String query) {
    _suggestionDebounce?.cancel();
    final generation = ++_suggestionGeneration;
    final current = _current.copyWith(query: query, errorMessage: null);
    if (query.trim().isEmpty) {
      state = AsyncData(current.copyWith(draftSuggestions: const []));
      return;
    }

    state = AsyncData(
      current.copyWith(
        draftSuggestions: _combinedSuggestions(
          history: current.searchHistory,
          localSuggestions: const {},
          query: query,
        ),
      ),
    );

    _suggestionDebounce = Timer(const Duration(milliseconds: 220), () async {
      final repository = ref.read(dictionaryRepositoryProvider);
      final localSuggestions = await repository.suggest(
        _current.configs,
        query,
      );
      if (generation != _suggestionGeneration ||
          query.trim() != _current.query.trim()) {
        return;
      }
      state = AsyncData(
        _current.copyWith(
          draftSuggestions: combineLookupSuggestions(
            history: _current.searchHistory,
            localSuggestions: localSuggestions,
            query: query,
          ),
        ),
      );
    });
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

  Future<void> setOnlineEnabled(String id, bool enabled) async {
    final current = _current;
    final repository = ref.read(dictionaryRepositoryProvider);
    final onlineConfigs = await repository.setOnlineEnabled(
      current.onlineConfigs,
      id,
      enabled,
    );
    state = AsyncData(current.copyWith(onlineConfigs: onlineConfigs));

    if (current.query.trim().isNotEmpty) {
      await search(current.query);
    }
  }

  void selectSource(int index) {
    state = AsyncData(
      _current.copyWith(selectedSourceIndex: index, selectedEntryIndex: 0),
    );
  }

  void selectEntry(int index) {
    state = AsyncData(_current.copyWith(selectedEntryIndex: index));
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

  Future<DictionarySearchResult> _searchOnlineSource(
    DictionaryRepository repository,
    OnlineDictionarySource source,
    String query,
  ) async {
    try {
      return await repository.searchOnline(source, query);
    } on OnlineDictionaryException catch (error) {
      return DictionarySearchResult(
        query: query,
        entries: const [],
        suggestions: const [],
        sourceErrors: {error.sourceName: error.message},
      );
    } catch (error) {
      return DictionarySearchResult(
        query: query,
        entries: const [],
        suggestions: const [],
        sourceErrors: {source.name: error.toString()},
      );
    }
  }

  List<String> _combinedSuggestions({
    required List<String> history,
    required Iterable<String> localSuggestions,
    required String query,
  }) => combineLookupSuggestions(
    history: history,
    localSuggestions: localSuggestions,
    query: query,
  );
}

List<String> combineLookupSuggestions({
  required List<String> history,
  required Iterable<String> localSuggestions,
  required String query,
  int limit = 12,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const [];
  }

  final combined = <String>[];
  final seen = <String>{};
  for (final suggestion in [
    ...history.where((item) => item.toLowerCase().contains(normalized)),
    ...localSuggestions,
  ]) {
    final trimmed = suggestion.trim();
    final key = trimmed.toLowerCase();
    if (trimmed.isEmpty || key == normalized || seen.contains(key)) {
      continue;
    }

    combined.add(trimmed);
    seen.add(key);
    if (combined.length >= limit) {
      break;
    }
  }

  return combined;
}

class DictionaryState {
  const DictionaryState({
    this.configs = const [],
    this.onlineConfigs = const [],
    this.result = DictionarySearchResult.empty,
    this.query = '',
    this.isSupported = true,
    this.isImporting = false,
    this.isSearching = false,
    this.errorMessage,
    this.lastImportedName,
    this.selectedSourceIndex = 0,
    this.selectedEntryIndex = 0,
    this.searchHistory = const [],
    this.draftSuggestions = const [],
  });

  final List<DictionaryConfig> configs;
  final List<OnlineDictionaryConfig> onlineConfigs;
  final DictionarySearchResult result;
  final String query;
  final bool isSupported;
  final bool isImporting;
  final bool isSearching;
  final String? errorMessage;
  final String? lastImportedName;
  final int selectedSourceIndex;
  final int selectedEntryIndex;
  final List<String> searchHistory;
  final List<String> draftSuggestions;

  bool get hasEnabledDictionary =>
      configs.any((config) => config.enabled) ||
      onlineConfigs.any((config) => config.enabled);

  List<String> get activeSourceLabels {
    final labels = <String>[];
    for (final key in result.entriesBySource.keys) {
      labels.add(key);
    }
    return labels;
  }

  DictionaryState copyWith({
    List<DictionaryConfig>? configs,
    List<OnlineDictionaryConfig>? onlineConfigs,
    DictionarySearchResult? result,
    String? query,
    bool? isSupported,
    bool? isImporting,
    bool? isSearching,
    String? errorMessage,
    String? lastImportedName,
    int? selectedSourceIndex,
    int? selectedEntryIndex,
    List<String>? searchHistory,
    List<String>? draftSuggestions,
  }) {
    return DictionaryState(
      configs: configs ?? this.configs,
      onlineConfigs: onlineConfigs ?? this.onlineConfigs,
      result: result ?? this.result,
      query: query ?? this.query,
      isSupported: isSupported ?? this.isSupported,
      isImporting: isImporting ?? this.isImporting,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      lastImportedName: lastImportedName ?? this.lastImportedName,
      selectedSourceIndex: selectedSourceIndex ?? this.selectedSourceIndex,
      selectedEntryIndex: selectedEntryIndex ?? this.selectedEntryIndex,
      searchHistory: searchHistory ?? this.searchHistory,
      draftSuggestions: draftSuggestions ?? this.draftSuggestions,
    );
  }
}
