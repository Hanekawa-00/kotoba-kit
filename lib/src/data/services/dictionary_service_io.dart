import 'dart:io';

import 'package:dict_reader/dict_reader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/dictionary_config.dart';
import '../models/dictionary_entry.dart';

class DictionaryService {
  final Map<String, DictReader> _readers = {};

  bool get isSupported => true;

  Future<DictionaryImportResult?> importFromPicker() async {
    const typeGroup = XTypeGroup(label: 'MDict', extensions: ['mdx']);
    final selected = await openFile(acceptedTypeGroups: [typeGroup]);

    if (selected == null) {
      return null;
    }

    final supportDir = await getApplicationSupportDirectory();
    final dictionariesDir = Directory(p.join(supportDir.path, 'dictionaries'));
    await dictionariesDir.create(recursive: true);

    final importedAt = DateTime.now();
    final sourceName = p.basenameWithoutExtension(selected.name);
    final id = _safeSegment(
      '${sourceName}_${importedAt.millisecondsSinceEpoch}',
    );
    final targetDir = Directory(p.join(dictionariesDir.path, id));
    await targetDir.create(recursive: true);

    final mdxPath = p.join(targetDir.path, selected.name);
    await selected.saveTo(mdxPath);

    String? mddPath;
    final sourcePath = selected.path;
    if (sourcePath.isNotEmpty) {
      final siblingMdd = File(p.setExtension(sourcePath, '.mdd'));
      if (await siblingMdd.exists()) {
        mddPath = p.join(targetDir.path, p.basename(siblingMdd.path));
        await siblingMdd.copy(mddPath);
      }
    }

    final reader = DictReader(mdxPath);
    try {
      await reader.initDict();
      final title = reader.header['Title']?.trim();
      final config = DictionaryConfig(
        id: id,
        name: title == null || title.isEmpty ? sourceName : title,
        mdxPath: mdxPath,
        mddPath: mddPath,
        importedAt: importedAt,
        enabled: true,
        entryCount: reader.numEntries,
      );

      _readers[mdxPath] = reader;

      return DictionaryImportResult(config: config, copiedMdd: mddPath != null);
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
        final definition = await reader.readOneMdx(match);
        entries.add(
          DictionaryEntry(
            word: match.keyText,
            definitionHtml: definition,
            sourceDictionary: dictionary.name,
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

  Future<void> deleteDictionaryFiles(DictionaryConfig config) async {
    final reader = _readers.remove(config.mdxPath);
    await reader?.close();

    final directory = Directory(p.dirname(config.mdxPath));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> dispose() async {
    final readers = _readers.values.toList(growable: false);
    _readers.clear();
    await Future.wait(readers.map((reader) => reader.close()));
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

  String _safeSegment(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_');
    return safe.isEmpty ? 'dictionary' : safe;
  }
}
