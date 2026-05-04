import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/data/repositories/dictionary_repository.dart';

void main() {
  test('normalizeSearchHistory deduplicates and caps recent items', () {
    final history = normalizeSearchHistory([
      ' 食べる ',
      '見る',
      '食べる',
      '',
      'TABERU',
      'taberu',
      '行く',
    ], maxItems: 4);

    expect(history, ['食べる', '見る', 'TABERU', '行く']);
  });
}
