import 'package:flutter/foundation.dart';

import 'dictionary_config.dart';

@immutable
class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.definitionHtml,
    required this.sourceDictionary,
  });

  final String word;
  final String definitionHtml;
  final String sourceDictionary;
}

@immutable
class DictionarySearchResult {
  const DictionarySearchResult({
    required this.query,
    required this.entries,
    required this.suggestions,
  });

  final String query;
  final List<DictionaryEntry> entries;
  final List<String> suggestions;

  static const empty = DictionarySearchResult(
    query: '',
    entries: [],
    suggestions: [],
  );
}

@immutable
class DictionaryImportResult {
  const DictionaryImportResult({required this.config, required this.copiedMdd});

  final DictionaryConfig config;
  final bool copiedMdd;
}
