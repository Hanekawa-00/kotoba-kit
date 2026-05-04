import 'package:flutter/foundation.dart';

import 'dictionary_config.dart';

@immutable
class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.definitionHtml,
    required this.sourceDictionary,
    this.resolvedWord,
    this.redirectChain = const [],
  });

  final String word;
  final String definitionHtml;
  final String sourceDictionary;
  final String? resolvedWord;
  final List<String> redirectChain;

  bool get isRedirected => resolvedWord != null && resolvedWord != word;
}

@immutable
class DictionarySearchResult {
  const DictionarySearchResult({
    required this.query,
    required this.entries,
    required this.suggestions,
    this.sourceErrors = const {},
  });

  final String query;
  final List<DictionaryEntry> entries;
  final List<String> suggestions;
  final Map<String, String> sourceErrors;

  static const empty = DictionarySearchResult(
    query: '',
    entries: [],
    suggestions: [],
  );

  Map<String, List<DictionaryEntry>> get entriesBySource {
    final grouped = <String, List<DictionaryEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.sourceDictionary, () => []).add(entry);
    }
    return grouped;
  }

  bool get hasSourceErrors => sourceErrors.isNotEmpty;
}

@immutable
class DictionaryImportResult {
  const DictionaryImportResult({required this.config, required this.copiedMdd});

  final DictionaryConfig config;
  final bool copiedMdd;
}
