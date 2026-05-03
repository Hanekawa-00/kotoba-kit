import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../../../data/models/dictionary_entry.dart';
import 'lru_cache.dart';
import 'online_dictionary_source.dart';

class WeblioSource implements OnlineDictionarySource {
  WeblioSource({Dio? dio}) : _dio = dio ?? _defaultDio();

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
  String get id => 'weblio';

  @override
  String get name => 'Weblio';

  @override
  String get baseUrl => 'https://www.weblio.jp';

  @override
  Future<DictionarySearchResult> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return DictionarySearchResult.empty;

    final cached = _cache.get(trimmed);
    if (cached != null) return cached;

    try {
      final encoded = Uri.encodeComponent(trimmed);
      final response = await _dio.get('$baseUrl/content/$encoded');
      final document = parser.parse(response.data as String);
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
    // Extract heading blocks (pbarT) and content blocks (kijiWrp)
    final headings = document.querySelectorAll('div.pbarT');
    final contents = document.querySelectorAll('div.kijiWrp');

    final entries = <DictionaryEntry>[];

    if (contents.isEmpty) {
      // Try alternate: some Weblio pages use different structure
      final mainContent = document.querySelector('div.kiji');
      if (mainContent != null) {
        final cleaned = _cleanHtml(mainContent);
        if (cleaned.trim().isNotEmpty) {
          entries.add(
            DictionaryEntry(
              word: query,
              definitionHtml: _wrapHtml(cleaned),
              sourceDictionary: name,
            ),
          );
        }
      }
      return entries;
    }

    for (var i = 0; i < contents.length; i++) {
      final headingHtml = i < headings.length
          ? _extractInnerHtml(headings[i])
          : '';
      final contentHtml = _cleanHtml(contents[i]);

      if (contentHtml.trim().isEmpty) continue;

      final combined = '$headingHtml$contentHtml';
      entries.add(
        DictionaryEntry(
          word: query,
          definitionHtml: _wrapHtml(combined),
          sourceDictionary: name,
        ),
      );
    }

    return entries;
  }

  String _extractInnerHtml(dom.Element element) {
    return element.innerHtml;
  }

  String _cleanHtml(dom.Element element) {
    // Remove script tags
    element.querySelectorAll('script').forEach((e) => e.remove());

    // Rewrite Weblio content links to JS callbacks
    element.querySelectorAll('a[href]').forEach((a) {
      final href = a.attributes['href'] ?? '';
      final contentMatch = RegExp(
        r'^https?://www\.weblio\.jp/content/(.+)$',
      ).firstMatch(href);
      if (contentMatch != null) {
        final word = Uri.decodeComponent(contentMatch.group(1)!);
        a.attributes['href'] =
            "javascript:safe_mdict_search_word('${_escapeJs(word)}')";
      }
      // Fix protocol-relative URLs
      if (href.startsWith('//')) {
        a.attributes['href'] = 'https:$href';
      }
    });

    // Fix protocol-relative src
    element.querySelectorAll('[src]').forEach((el) {
      final src = el.attributes['src'] ?? '';
      if (src.startsWith('//')) {
        el.attributes['src'] = 'https:$src';
      }
    });

    return element.innerHtml;
  }

  String _wrapHtml(String content) {
    return '<style>'
        'div.lunaweb { font-family: "Hiragino Sans", "Yu Gothic", sans-serif; }'
        'div.lunaweb .pbarT { background: var(--surface-container); '
        'padding: 8px 12px; margin: 8px 0; border-radius: 8px; }'
        'div.lunaweb .kijiWrp { padding: 4px 0; }'
        'div.lunaweb a { color: var(--primary); }'
        'div.lunaweb .lgDictLg, div.lunaweb .lgDictSp { filter: none; }'
        '</style>'
        '<div class="lunaweb">$content</div>';
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
