import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

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
        responseType: ResponseType.plain,
        headers: {
          'User-Agent': 'KotobaKit/1.0',
          'Accept': 'text/html,application/xhtml+xml',
        },
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
      final encoded = Uri.encodeComponent(trimmed);
      final response = await _dio.get('$baseUrl/search/$encoded');
      final document = parser.parse(response.data as String);

      // Check for no matches
      if (document.querySelector('#no-matches') != null) {
        final result = DictionarySearchResult(
          query: trimmed,
          entries: const [],
          suggestions: const [],
        );
        _cache.put(trimmed, result);
        return result;
      }

      final entries = _extractEntries(document, trimmed);
      final result = DictionarySearchResult(
        query: trimmed,
        entries: entries,
        suggestions: const [],
      );

      _cache.put(trimmed, result);
      return result;
    } on DioException {
      return DictionarySearchResult(
        query: trimmed,
        entries: const [],
        suggestions: const [],
      );
    }
  }

  List<DictionaryEntry> _extractEntries(dom.Document document, String query) {
    final mainResults = document.querySelector('#main_results');
    if (mainResults == null) return const [];

    // Clean up unwanted content before extracting
    _cleanContent(mainResults);

    // Each result entry in Jisho is typically a row in the results
    // Split by primary result blocks
    final resultBlocks = mainResults.querySelectorAll(
      'div.concept_light.clearfix',
    );

    if (resultBlocks.isEmpty) {
      // Fallback: return entire main_results as one entry
      final cleaned = mainResults.innerHtml;
      if (cleaned.trim().isEmpty) return const [];
      return [
        DictionaryEntry(
          word: query,
          definitionHtml: _wrapHtml(cleaned),
          sourceDictionary: name,
        ),
      ];
    }

    final entries = <DictionaryEntry>[];
    for (final block in resultBlocks) {
      // Extract the Japanese word for this entry
      final kanjiEl = block.querySelector(
        '.concept_light-representation .text',
      );
      final word = kanjiEl?.text.trim() ?? query;

      final cleaned = block.innerHtml;
      if (cleaned.trim().isEmpty) continue;

      entries.add(
        DictionaryEntry(
          word: word,
          definitionHtml: _wrapHtml(cleaned),
          sourceDictionary: name,
        ),
      );
    }

    return entries;
  }

  void _cleanContent(dom.Element container) {
    // Remove audio links
    container.querySelectorAll('a.concept_audio').forEach((e) => e.remove());
    container
        .querySelectorAll('a.concept_light-status_link')
        .forEach((e) => e.remove());

    // Remove login prompts
    container.querySelectorAll('a.signin').forEach((e) => e.remove());

    // Remove "Discussions" heading
    final h3s = container.querySelectorAll('h3');
    for (final h3 in h3s) {
      if (h3.text.contains('Discussions')) {
        h3.remove();
        // Also remove following sibling discussion section if present
        var next = h3.nextElementSibling;
        while (next != null &&
            (next.classes.contains('discussions') ||
                next.classes.contains('discussion'))) {
          final toRemove = next;
          next = next.nextElementSibling;
          toRemove.remove();
        }
      }
    }

    // Remove other_dictionaries section
    container.querySelector('#other_dictionaries')?.remove();

    // Fix protocol-relative URLs
    container.querySelectorAll('[src]').forEach((el) {
      final src = el.attributes['src'] ?? '';
      if (src.startsWith('//')) {
        el.attributes['src'] = 'https:$src';
      }
    });

    container.querySelectorAll('a[href]').forEach((a) {
      final href = a.attributes['href'] ?? '';
      if (href.startsWith('//')) {
        a.attributes['href'] = 'https:$href';
      }
      // Rewrite Jisho search links
      if (href.startsWith('/search/') || href.startsWith('/word/')) {
        final parts = href.split('/');
        if (parts.length >= 3) {
          final word = Uri.decodeComponent(parts.last);
          a.attributes['href'] =
              "javascript:safe_mdict_search_word('${_escapeJs(word)}')";
        }
      }
    });

    // Remove script tags
    container.querySelectorAll('script').forEach((e) => e.remove());
  }

  String _wrapHtml(String content) {
    return '<style>'
        'div.lunajisho { font-family: "Hiragino Sans", "Yu Gothic", sans-serif; }'
        'div.lunajisho .concept_light { padding: 8px 0; border-bottom: 1px solid var(--outline-variant); }'
        'div.lunajisho .concept_light-representation { font-size: 1.2em; font-weight: 600; }'
        'div.lunajisho .concept_light-meanings { padding: 4px 0; }'
        'div.lunajisho .meaning-tags { font-size: 0.85em; opacity: 0.7; }'
        'div.lunajisho a { color: var(--primary); }'
        '</style>'
        '<div class="lunajisho">$content</div>';
  }

  String _escapeJs(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n');
  }

  @override
  Future<void> dispose() async {
    _cache.clear();
    _dio.close();
  }
}
