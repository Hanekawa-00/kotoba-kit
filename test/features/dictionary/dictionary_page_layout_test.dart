import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop side panel does not duplicate source switching controls', () {
    final source = File(
      'lib/src/features/dictionary/dictionary_page.dart',
    ).readAsStringSync();
    final sidePanel = _classBody(source, '_LookupSidePanel', '_SearchRow');
    final resultPane = _classBody(source, '_ResultPane', '_StartPanel');
    final readingPanel = _classBody(source, '_ReadingPanel', '_SourceSwitcher');

    expect(sidePanel, isNot(contains('ChoiceChip')));
    expect(sidePanel, isNot(contains('selectSource')));
    expect(resultPane, contains('_SourceSwitcher'));
    expect(readingPanel, isNot(contains('_SourceSwitcher')));
  });

  test('lookup assist stays in the text field tap region', () {
    final source = File(
      'lib/src/features/dictionary/dictionary_page.dart',
    ).readAsStringSync();
    final topSearchBar = _classBody(
      source,
      '_TopSearchBar',
      '_LookupSidePanel',
    );
    final sidePanel = _classBody(source, '_LookupSidePanel', '_SearchRow');

    expect(topSearchBar, contains('TextFieldTapRegion'));
    expect(sidePanel, contains('TextFieldTapRegion'));
  });
}

String _classBody(String source, String startClass, String nextClass) {
  final start = source.indexOf('class $startClass');
  final end = source.indexOf('class $nextClass', start);

  expect(start, isNonNegative);
  expect(end, isNonNegative);

  return source.substring(start, end);
}
