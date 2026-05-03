import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jisho_source.dart';
import 'online_dictionary_source.dart';
import 'weblio_source.dart';

final onlineSourcesProvider = Provider<List<OnlineDictionarySource>>((ref) {
  return [WeblioSource(), JishoSource()];
});
