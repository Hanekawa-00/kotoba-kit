import 'dart:convert';
import 'dart:io';

import 'package:dict_reader/dict_reader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/dictionary_config.dart';
import '../models/dictionary_entry.dart';

class DictionaryService {
  final Map<String, DictReader> _readers = {};
  final Map<String, DictReader> _mddReaders = {};

  bool get isSupported => true;

  Future<DictionaryImportResult?> importFromPicker() async {
    const typeGroup = XTypeGroup(label: 'MDict', extensions: ['mdx', 'mdd']);
    final selectedFiles = await openFiles(acceptedTypeGroups: [typeGroup]);

    if (selectedFiles.isEmpty) {
      return null;
    }

    final selected = selectMdxFileForImport(selectedFiles);
    if (selected == null) {
      throw const FormatException('Please select an .mdx dictionary file.');
    }

    final supportDir = await getApplicationSupportDirectory();
    final dictionariesDir = Directory(p.join(supportDir.path, 'dictionaries'));
    await dictionariesDir.create(recursive: true);

    final importedAt = DateTime.now();
    final selectedName = displayFileNameForImport(selected);
    final sourceName = p.basenameWithoutExtension(selectedName);
    final id = _safeSegment(
      '${sourceName}_${importedAt.millisecondsSinceEpoch}',
    );
    final targetDir = Directory(p.join(dictionariesDir.path, id));
    await targetDir.create(recursive: true);

    final mdxFileName = ensureFileExtensionForImport(selectedName, '.mdx');
    final mdxPath = p.join(targetDir.path, mdxFileName);
    await selected.saveTo(mdxPath);

    final mddPaths = <String>[];
    final copiedMddNames = <String>{};
    for (final selectedMdd in selectedFiles.where(
      (file) => _selectedFileExtension(file) == '.mdd',
    )) {
      final mddName = ensureFileExtensionForImport(
        displayFileNameForImport(selectedMdd),
        '.mdd',
      );
      final targetPath = p.join(targetDir.path, mddName);
      await selectedMdd.saveTo(targetPath);
      mddPaths.add(targetPath);
      copiedMddNames.add(mddName.toLowerCase());
    }

    for (final siblingMdd in await _siblingMddFiles(selected.path)) {
      final name = p.basename(siblingMdd.path);
      if (copiedMddNames.contains(name.toLowerCase())) {
        continue;
      }

      final targetPath = p.join(targetDir.path, name);
      await siblingMdd.copy(targetPath);
      mddPaths.add(targetPath);
      copiedMddNames.add(name.toLowerCase());
    }

    final reader = DictReader(mdxPath);
    try {
      await reader.initDict();
      final title = reader.header['Title']?.trim();
      final config = DictionaryConfig(
        id: id,
        name: title == null || title.isEmpty ? sourceName : title,
        mdxPath: mdxPath,
        mddPaths: mddPaths,
        importedAt: importedAt,
        enabled: true,
        entryCount: reader.numEntries,
      );

      _readers[mdxPath] = reader;

      return DictionaryImportResult(
        config: config,
        copiedMdd: mddPaths.isNotEmpty,
      );
    } catch (_) {
      await reader.close();
      await targetDir.delete(recursive: true);
      rethrow;
    }
  }

  Future<DictionarySearchResult> search(
    List<DictionaryConfig> dictionaries,
    String query,
  ) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return DictionarySearchResult.empty;
    }

    final entries = <DictionaryEntry>[];
    final suggestions = <String>{};

    for (final dictionary in dictionaries.where((item) => item.enabled)) {
      final reader = await _readerFor(dictionary);
      final matches = await reader.locateAll(normalizedQuery);

      for (final match in matches) {
        entries.addAll(
          await _readResolvedEntries(
            dictionary: dictionary,
            reader: reader,
            match: match,
            displayWord: match.keyText,
          ),
        );
      }

      if (matches.isEmpty) {
        suggestions.addAll(
          reader
              .search(normalizedQuery, limit: 8)
              .where((word) => word != normalizedQuery),
        );
      }
    }

    return DictionarySearchResult(
      query: normalizedQuery,
      entries: entries,
      suggestions: suggestions.take(12).toList(growable: false),
    );
  }

  Future<List<String>> suggest(
    List<DictionaryConfig> dictionaries,
    String query,
  ) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final suggestions = <String>{};
    for (final dictionary in dictionaries.where((item) => item.enabled)) {
      final reader = await _readerFor(dictionary);
      suggestions.addAll(
        reader
            .search(normalizedQuery, limit: 8)
            .where((word) => word != normalizedQuery),
      );
      if (suggestions.length >= 12) {
        break;
      }
    }

    return suggestions.take(12).toList(growable: false);
  }

  Future<void> deleteDictionaryFiles(DictionaryConfig config) async {
    final reader = _readers.remove(config.mdxPath);
    await reader?.close();
    for (final mddPath in config.mddPaths) {
      final mddReader = _mddReaders.remove(mddPath);
      await mddReader?.close();
    }

    final directory = Directory(p.dirname(config.mdxPath));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> dispose() async {
    final readers = _readers.values.toList(growable: false);
    final mddReaders = _mddReaders.values.toList(growable: false);
    _readers.clear();
    _mddReaders.clear();
    await Future.wait([
      ...readers.map((reader) => reader.close()),
      ...mddReaders.map((reader) => reader.close()),
    ]);
  }

  Future<DictReader> _readerFor(DictionaryConfig config) async {
    final cached = _readers[config.mdxPath];
    if (cached != null) {
      return cached;
    }

    final reader = DictReader(config.mdxPath);
    await reader.initDict();
    _readers[config.mdxPath] = reader;
    return reader;
  }

  Future<List<DictionaryEntry>> _readResolvedEntries({
    required DictionaryConfig dictionary,
    required DictReader reader,
    required RecordOffsetInfo match,
    required String displayWord,
    Set<String> visited = const {},
    List<String> redirectChain = const [],
    int depth = 0,
  }) async {
    final definition = _cleanRecord(await reader.readOneMdx(match));
    final target = _extractMdictLink(definition);

    if (target == null || depth >= 8 || visited.contains(target)) {
      final repairedDefinition = await _repairMdictHtml(definition, dictionary);
      return [
        DictionaryEntry(
          word: displayWord,
          resolvedWord: displayWord == match.keyText ? null : match.keyText,
          definitionHtml: repairedDefinition,
          sourceDictionary: dictionary.name,
          redirectChain: redirectChain,
        ),
      ];
    }

    final linkedMatches = await reader.locateAll(target);
    if (linkedMatches.isEmpty) {
      final repairedDefinition = await _repairMdictHtml(definition, dictionary);
      return [
        DictionaryEntry(
          word: displayWord,
          resolvedWord: target,
          definitionHtml: repairedDefinition,
          sourceDictionary: dictionary.name,
          redirectChain: [...redirectChain, target],
        ),
      ];
    }

    final resolved = <DictionaryEntry>[];
    for (final linkedMatch in linkedMatches) {
      resolved.addAll(
        await _readResolvedEntries(
          reader: reader,
          match: linkedMatch,
          dictionary: dictionary,
          displayWord: displayWord,
          visited: {...visited, match.keyText, target},
          redirectChain: [...redirectChain, target],
          depth: depth + 1,
        ),
      );
    }

    return resolved;
  }

  Future<String> _repairMdictHtml(
    String html,
    DictionaryConfig dictionary,
  ) async {
    final collectedCss = <String>[];
    final attributePattern = RegExp(
      r'''(src|href)\s*=\s*(["'])(.*?)\2''',
      caseSensitive: false,
    );
    final buffer = StringBuffer();
    var cursor = 0;

    for (final match in attributePattern.allMatches(html)) {
      buffer.write(html.substring(cursor, match.start));
      final replacement = await _repairMdictAttribute(
        dictionary: dictionary,
        attribute: match.group(1)!,
        quote: match.group(2)!,
        url: match.group(3)!,
        collectedCss: collectedCss,
      );
      buffer.write(replacement);
      cursor = match.end;
    }

    buffer.write(html.substring(cursor));
    if (collectedCss.isEmpty) {
      return buffer.toString();
    }

    return '${buffer.toString()}<style>\n${collectedCss.join('\n')}\n</style>';
  }

  Future<String> _repairMdictAttribute({
    required DictionaryConfig dictionary,
    required String attribute,
    required String quote,
    required String url,
    required List<String> collectedCss,
  }) async {
    final normalizedAttribute = attribute.toLowerCase();
    if (_shouldKeepMdictUrl(url)) {
      return '$attribute=$quote$url$quote';
    }

    if (url.startsWith('entry://')) {
      final target = url.substring('entry://'.length);
      return '$attribute=$quote'
          "javascript:safe_mdict_search_word('${_escapeJsString(target)}')"
          '$quote';
    }

    if (url.startsWith('sound://')) {
      final resource = await _readMddResource(
        dictionary,
        url.substring('sound://'.length),
      );
      if (resource == null) {
        return '$attribute=$quote$url$quote';
      }

      final mime = _mimeType(url);
      final encoded = _base64(resource);
      return '$attribute=$quote'
          "javascript:mdict_play_sound('$mime','$encoded')"
          '$quote';
    }

    final isStylesheet =
        normalizedAttribute == 'href' &&
        url.split('?').first.toLowerCase().endsWith('.css');

    final localResource = await _readLocalDictionaryResource(dictionary, url);
    final mddResource =
        localResource ?? await _readMddResource(dictionary, url);
    if (mddResource == null) {
      return '$attribute=$quote$url$quote';
    }

    if (isStylesheet) {
      final css = await _repairCssUrls(
        dictionary,
        String.fromCharCodes(mddResource),
      );
      if (css.trim().isNotEmpty) {
        collectedCss.add(css);
      }
      return '';
    }

    final mime = _mimeType(url);
    return '$attribute=$quote'
        'data:$mime;base64,${_base64(mddResource)}'
        '$quote';
  }

  Future<String> _repairCssUrls(DictionaryConfig dictionary, String css) async {
    final urlPattern = RegExp(
      r'''url\(\s*(["']?)(.*?)\1\s*\)''',
      caseSensitive: false,
    );
    final buffer = StringBuffer();
    var cursor = 0;

    for (final match in urlPattern.allMatches(css)) {
      buffer.write(css.substring(cursor, match.start));
      final url = match.group(2)!;
      if (_shouldKeepMdictUrl(url)) {
        buffer.write(match.group(0));
      } else {
        final resource =
            await _readLocalDictionaryResource(dictionary, url) ??
            await _readMddResource(dictionary, url);
        if (resource == null) {
          buffer.write(match.group(0));
        } else {
          buffer.write(
            'url("data:${_mimeType(url)};base64,${_base64(resource)}")',
          );
        }
      }
      cursor = match.end;
    }

    buffer.write(css.substring(cursor));
    return buffer.toString();
  }

  Future<List<int>?> _readLocalDictionaryResource(
    DictionaryConfig dictionary,
    String url,
  ) async {
    final normalizedUrl = _stripUrlQuery(url).replaceAll('/', p.separator);
    final file = File(
      p.normalize(p.join(p.dirname(dictionary.mdxPath), normalizedUrl)),
    );
    if (!await file.exists()) {
      return null;
    }

    return file.readAsBytes();
  }

  Future<List<int>?> _readMddResource(
    DictionaryConfig dictionary,
    String url,
  ) async {
    final readers = await _mddReadersFor(dictionary);
    if (readers.isEmpty) {
      return null;
    }

    final normalized = _normalizeMddKey(url);
    for (final reader in readers) {
      for (final candidate in {
        normalized,
        normalized.replaceAll('/', '\\'),
        normalized.replaceAll('\\', '/'),
        normalized.startsWith('/') ? normalized.substring(1) : '/$normalized',
        normalized.startsWith('\\') ? normalized.substring(1) : '\\$normalized',
      }) {
        final matches = await reader.locateAll(candidate);
        if (matches.isNotEmpty) {
          return reader.readOneMdd(matches.first);
        }
      }
    }

    return null;
  }

  Future<List<DictReader>> _mddReadersFor(DictionaryConfig dictionary) async {
    final readers = <DictReader>[];
    for (final mddPath in dictionary.mddPaths) {
      if (mddPath.isEmpty || !await File(mddPath).exists()) {
        continue;
      }

      final cached = _mddReaders[mddPath];
      if (cached != null) {
        readers.add(cached);
        continue;
      }

      final reader = DictReader(mddPath);
      await reader.initDict();
      _mddReaders[mddPath] = reader;
      readers.add(reader);
    }

    return readers;
  }

  Future<List<File>> _siblingMddFiles(String mdxSourcePath) async {
    if (mdxSourcePath.isEmpty) {
      return const [];
    }

    final mdxFile = File(mdxSourcePath);
    final parent = mdxFile.parent;
    if (!await parent.exists()) {
      return const [];
    }

    final baseName = p.basenameWithoutExtension(mdxSourcePath);
    final pattern = RegExp(
      '^${RegExp.escape(baseName)}(?:\\.\\d+)?\\.mdd\$',
      caseSensitive: false,
    );
    final files = <File>[];
    await for (final entity in parent.list(followLinks: false)) {
      if (entity is File && pattern.hasMatch(p.basename(entity.path))) {
        files.add(entity);
      }
    }

    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files;
  }

  String _selectedFileExtension(XFile file) =>
      selectedFileExtensionForImport(file);

  String _cleanRecord(String value) {
    return value.replaceAll('\u0000', '').trim();
  }

  String? _extractMdictLink(String value) {
    final firstLine = value
        .replaceAll('\r\n', '\n')
        .split('\n')
        .first
        .replaceAll('\u0000', '')
        .trim();
    final match = RegExp(r'^@@@LINK=(.+)$').firstMatch(firstLine);
    final target = match?.group(1)?.trim();

    if (target == null || target.isEmpty) {
      return null;
    }

    return target;
  }

  String _safeSegment(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_');
    return safe.isEmpty ? 'dictionary' : safe;
  }

  bool _shouldKeepMdictUrl(String url) {
    final lower = url.toLowerCase();
    return url.isEmpty ||
        url.startsWith('#') ||
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('data:') ||
        lower.startsWith('javascript:') ||
        lower.startsWith('mailto:');
  }

  String _stripUrlQuery(String url) {
    return url.replaceFirst(RegExp(r'[#?].*$'), '');
  }

  String _normalizeMddKey(String url) {
    final normalized = Uri.decodeFull(
      _stripUrlQuery(url),
    ).replaceAll('\\', '/');
    if (normalized.startsWith('./')) {
      return normalized.substring(2);
    }
    return normalized;
  }

  String _base64(List<int> data) => base64Encode(data);

  String _mimeType(String url) {
    final extension = p.extension(_stripUrlQuery(url)).toLowerCase();
    return switch (extension) {
      '.css' => 'text/css',
      '.js' => 'text/javascript',
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.svg' => 'image/svg+xml',
      '.webp' => 'image/webp',
      '.mp3' => 'audio/mpeg',
      '.wav' => 'audio/wav',
      '.ogg' || '.oga' => 'audio/ogg',
      '.aac' => 'audio/aac',
      '.opus' => 'audio/opus',
      '.spx' => 'audio/ogg',
      '.ttf' => 'font/ttf',
      '.otf' => 'font/otf',
      '.woff' => 'font/woff',
      '.woff2' => 'font/woff2',
      _ => 'application/octet-stream',
    };
  }

  String _escapeJsString(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n');
  }
}

@visibleForTesting
XFile? selectMdxFileForImport(List<XFile> selectedFiles) {
  for (final file in selectedFiles) {
    if (selectedFileExtensionForImport(file) == '.mdx') {
      return file;
    }
  }

  if (selectedFiles.length == 1 &&
      selectedFileExtensionForImport(selectedFiles.single) != '.mdd') {
    return selectedFiles.single;
  }

  return null;
}

@visibleForTesting
String selectedFileExtensionForImport(XFile file) {
  final pathExtension = p.extension(file.path).toLowerCase();
  if (pathExtension.isNotEmpty) {
    return pathExtension;
  }

  return p.extension(file.name).toLowerCase();
}

@visibleForTesting
String displayFileNameForImport(XFile file) {
  final name = file.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  final pathName = p.basename(file.path).trim();
  return pathName.isEmpty ? 'dictionary' : pathName;
}

@visibleForTesting
String ensureFileExtensionForImport(String fileName, String extension) {
  if (p.extension(fileName).isNotEmpty) {
    return fileName;
  }

  return '$fileName$extension';
}
