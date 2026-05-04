import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/data/services/online_sources/jisho_source.dart';

void main() {
  test('parseJishoSearchResponse parses JSON words', () {
    final entries = parseJishoSearchResponse(
      {
        'data': [
          {
            'japanese': [
              {'word': '食べる', 'reading': 'たべる'},
            ],
            'senses': [
              {
                'parts_of_speech': ['Ichidan verb', 'Transitive verb'],
                'english_definitions': ['to eat'],
              },
            ],
          },
        ],
      },
      '食べる',
      'Jisho',
    );

    expect(entries, hasLength(1));
    expect(entries.single.word, '食べる');
    expect(entries.single.sourceDictionary, 'Jisho');
    expect(entries.single.definitionHtml, contains('たべる'));
    expect(entries.single.definitionHtml, contains('to eat'));
  });
}
