import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/data/models/dictionary_config.dart';
import 'package:kotoba_kit/src/data/models/dictionary_entry.dart';
import 'package:kotoba_kit/src/data/models/online_dictionary_config.dart';
import 'package:kotoba_kit/src/data/repositories/dictionary_repository.dart';
import 'package:kotoba_kit/src/data/services/online_sources/online_dictionary_source.dart';
import 'package:kotoba_kit/src/data/services/online_sources/online_source_providers.dart';
import 'package:kotoba_kit/src/features/dictionary/dictionary_providers.dart';

void main() {
  test('combineLookupSuggestions merges history before local suggestions', () {
    final suggestions = combineLookupSuggestions(
      history: ['食べる', '食べ物', '見る'],
      localSuggestions: ['食べ頃', '食べる', '食堂'],
      query: '食べ',
    );

    expect(suggestions, ['食べる', '食べ物', '食べ頃', '食堂']);
  });

  test(
    'stale search completions do not overwrite newer lookup state',
    () async {
      final repository = _DelayedSearchRepository();
      final container = ProviderContainer(
        overrides: [
          dictionaryRepositoryProvider.overrideWithValue(repository),
          onlineSourcesProvider.overrideWithValue([const _FakeOnlineSource()]),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dictionaryControllerProvider.future);
      final controller = container.read(dictionaryControllerProvider.notifier);

      final slowSearch = controller.search('slow');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.search('fast');
      await slowSearch;

      final state = await container.read(dictionaryControllerProvider.future);
      expect(state.result.query, 'fast');
      expect(state.result.entries.single.word, 'fast');
    },
  );
}

class _DelayedSearchRepository implements DictionaryRepository {
  @override
  bool get isSupported => true;

  @override
  Future<void> deleteDictionary(
    List<DictionaryConfig> configs,
    DictionaryConfig config,
  ) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<DictionaryImportResult?> importDictionary() async => null;

  @override
  Future<List<DictionaryConfig>> loadConfigs() async => const [];

  @override
  Future<List<OnlineDictionaryConfig>> loadOnlineConfigs() async => const [
    OnlineDictionaryConfig(id: 'fake', name: 'Fake', enabled: true),
  ];

  @override
  Future<List<String>> loadSearchHistory() async => const [];

  @override
  Future<void> saveConfigs(List<DictionaryConfig> configs) async {}

  @override
  Future<void> saveOnlineConfigs(List<OnlineDictionaryConfig> configs) async {}

  @override
  Future<List<String>> saveSearchHistory(List<String> history) async => history;

  @override
  Future<DictionarySearchResult> search(
    List<DictionaryConfig> configs,
    String query,
  ) async {
    return DictionarySearchResult(
      query: query,
      entries: const [],
      suggestions: const [],
    );
  }

  @override
  Future<DictionarySearchResult> searchOnline(
    OnlineDictionarySource source,
    String query,
  ) async {
    if (query == 'slow') {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }

    return DictionarySearchResult(
      query: query,
      entries: [
        DictionaryEntry(
          word: query,
          definitionHtml: query,
          sourceDictionary: source.name,
        ),
      ],
      suggestions: const [],
    );
  }

  @override
  Future<List<DictionaryConfig>> setEnabled(
    List<DictionaryConfig> configs,
    String id,
    bool enabled,
  ) async {
    return configs;
  }

  @override
  Future<List<OnlineDictionaryConfig>> setOnlineEnabled(
    List<OnlineDictionaryConfig> configs,
    String id,
    bool enabled,
  ) async {
    return [
      for (final config in configs)
        if (config.id == id) config.copyWith(enabled: enabled) else config,
    ];
  }

  @override
  Future<List<String>> suggest(
    List<DictionaryConfig> configs,
    String query,
  ) async {
    return const [];
  }
}

class _FakeOnlineSource implements OnlineDictionarySource {
  const _FakeOnlineSource();

  @override
  String get baseUrl => 'https://example.test';

  @override
  String get id => 'fake';

  @override
  String get name => 'Fake';

  @override
  Future<void> dispose() async {}

  @override
  Future<DictionarySearchResult> search(String query) {
    throw UnimplementedError();
  }
}
