import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/data/models/dictionary_config.dart';

void main() {
  test('migrates legacy mddPath to mddPaths', () {
    final config = DictionaryConfig.fromJson({
      'id': 'dict',
      'name': 'Dictionary',
      'mdxPath': 'dictionary.mdx',
      'mddPath': 'dictionary.mdd',
      'importedAt': '2026-05-04T00:00:00.000',
      'enabled': true,
    });

    expect(config.mddPath, 'dictionary.mdd');
    expect(config.mddPaths, ['dictionary.mdd']);
  });

  test('prefers persisted mddPaths when available', () {
    final config = DictionaryConfig.fromJson({
      'id': 'dict',
      'name': 'Dictionary',
      'mdxPath': 'dictionary.mdx',
      'mddPath': 'dictionary.mdd',
      'mddPaths': ['dictionary.mdd', 'dictionary.1.mdd'],
      'importedAt': '2026-05-04T00:00:00.000',
      'enabled': true,
    });

    expect(config.mddPath, 'dictionary.mdd');
    expect(config.mddPaths, ['dictionary.mdd', 'dictionary.1.mdd']);
  });
}
