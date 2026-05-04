import 'package:dio/dio.dart';
import '../../../data/models/dictionary_entry.dart';
import 'lru_cache.dart';
import 'online_dictionary_source.dart';

class JishoSource implements OnlineDictionarySource {
  JishoSource({Dio? dio}) : _dio = dio ?? _defaultDio();

  final Dio _dio;
  final _cache = LRUCache<String, DictionarySearchResult>(maxSize: 32);

  static Dio _defaultDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        responseType: ResponseType.json,
        headers: {'User-Agent': 'KotobaKit/1.0', 'Accept': 'application/json'},
      ),
    );
  }

  @override
  String get id => 'jisho';

  @override
  String get name => 'Jisho';

  @override
  String get baseUrl => 'https://jisho.org';

  @override
  Future<DictionarySearchResult> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return DictionarySearchResult.empty;

    final cached = _cache.get(trimmed);
    if (cached != null) return cached;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/v1/search/words',
        queryParameters: {'keyword': trimmed},
      );
      final entries = parseJishoSearchResponse(response.data, trimmed, name);
      final result = DictionarySearchResult(
        query: trimmed,
        entries: entries,
        suggestions: const [],
      );

      _cache.put(trimmed, result);
      return result;
    } on DioException catch (error) {
      throw OnlineDictionaryException(name, _messageForDio(error));
    } on FormatException catch (error) {
      throw OnlineDictionaryException(name, error.message);
    }
  }

  String _messageForDio(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'connection timed out',
      DioExceptionType.badResponse =>
        'HTTP ${error.response?.statusCode ?? 'error'}',
      DioExceptionType.connectionError => 'network connection failed',
      _ => error.message ?? 'request failed',
    };
  }

  @override
  Future<void> dispose() async {
    _cache.clear();
    _dio.close();
  }
}

List<DictionaryEntry> parseJishoSearchResponse(
  Map<String, dynamic>? data,
  String query,
  String sourceName,
) {
  final rawEntries = data?['data'];
  if (rawEntries is! List) {
    throw const FormatException('Unexpected Jisho response.');
  }

  final entries = <DictionaryEntry>[];
  for (final rawEntry in rawEntries.take(8)) {
    if (rawEntry is! Map<String, dynamic>) {
      continue;
    }

    final word = _primaryWord(rawEntry, query);
    final html = _entryHtml(rawEntry);
    if (html.trim().isEmpty) {
      continue;
    }

    entries.add(
      DictionaryEntry(
        word: word,
        definitionHtml: _wrapHtml(html),
        sourceDictionary: sourceName,
      ),
    );
  }

  return entries;
}

String _primaryWord(Map<String, dynamic> entry, String fallback) {
  final japanese = entry['japanese'];
  if (japanese is! List || japanese.isEmpty) {
    return fallback;
  }

  for (final raw in japanese) {
    if (raw is Map<String, dynamic>) {
      final word = raw['word']?.toString().trim();
      if (word != null && word.isNotEmpty) {
        return word;
      }
    }
  }

  for (final raw in japanese) {
    if (raw is Map<String, dynamic>) {
      final reading = raw['reading']?.toString().trim();
      if (reading != null && reading.isNotEmpty) {
        return reading;
      }
    }
  }

  return fallback;
}

String _entryHtml(Map<String, dynamic> entry) {
  final parts = <String>[];
  final japanese = entry['japanese'];
  if (japanese is List && japanese.isNotEmpty) {
    parts.add('<div class="jisho-forms">');
    for (final raw in japanese) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final word = raw['word']?.toString();
      final reading = raw['reading']?.toString();
      if ((word == null || word.isEmpty) &&
          (reading == null || reading.isEmpty)) {
        continue;
      }
      parts.add('<div class="jisho-form">');
      if (word != null && word.isNotEmpty) {
        parts.add('<span class="jisho-word">${_escapeHtml(word)}</span>');
      }
      if (reading != null && reading.isNotEmpty && reading != word) {
        parts.add('<span class="jisho-reading">${_escapeHtml(reading)}</span>');
      }
      parts.add('</div>');
    }
    parts.add('</div>');
  }

  final senses = entry['senses'];
  if (senses is List && senses.isNotEmpty) {
    parts.add('<ol class="jisho-senses">');
    for (final rawSense in senses) {
      if (rawSense is! Map<String, dynamic>) {
        continue;
      }
      final tags = _stringList(rawSense['parts_of_speech']);
      final definitions = _stringList(rawSense['english_definitions']);
      if (definitions.isEmpty) {
        continue;
      }
      parts.add('<li>');
      if (tags.isNotEmpty) {
        parts.add(
          '<div class="jisho-tags">${_escapeHtml(tags.join(', '))}</div>',
        );
      }
      parts.add(_escapeHtml(definitions.join('; ')));
      parts.add('</li>');
    }
    parts.add('</ol>');
  }

  return parts.join();
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _wrapHtml(String content) {
  return '<style>'
      'div.lunajisho { font-family: "Hiragino Sans", "Yu Gothic", sans-serif; }'
      'div.lunajisho .jisho-form { display: flex; gap: 0.75em; align-items: baseline; margin: 0 0 0.35em; }'
      'div.lunajisho .jisho-word { font-size: 1.25em; font-weight: 700; }'
      'div.lunajisho .jisho-reading { color: var(--on-surface-variant); }'
      'div.lunajisho .jisho-senses { margin: 0.75em 0 0; padding-left: 1.5em; }'
      'div.lunajisho .jisho-tags { font-size: 0.85em; color: var(--on-surface-variant); margin-bottom: 0.2em; }'
      'div.lunajisho a { color: var(--primary); }'
      '</style>'
      '<div class="lunajisho">$content</div>';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
