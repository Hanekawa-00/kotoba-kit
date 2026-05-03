import '../../../data/models/dictionary_entry.dart';

abstract class OnlineDictionarySource {
  String get id;
  String get name;
  String get baseUrl;

  Future<DictionarySearchResult> search(String query);

  Future<void> dispose() async {}
}
