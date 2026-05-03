import '../models/dictionary_config.dart';
import '../models/dictionary_entry.dart';

class DictionaryService {
  bool get isSupported => false;

  Future<DictionaryImportResult?> importFromPicker() async {
    throw UnsupportedError(
      'Local MDict import is not supported on this platform.',
    );
  }

  Future<DictionarySearchResult> search(
    List<DictionaryConfig> dictionaries,
    String query,
  ) async {
    return DictionarySearchResult.empty;
  }

  Future<void> deleteDictionaryFiles(DictionaryConfig config) async {}

  Future<void> dispose() async {}
}
