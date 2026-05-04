import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/data/services/dictionary_service_io.dart';

void main() {
  group('MDict import file selection', () {
    test('selects the mdx file when resources are selected together', () {
      final mdx = XFile('daijisen.mdx');
      final mdd = XFile('daijisen.1.mdd');

      expect(selectMdxFileForImport([mdd, mdx]), same(mdx));
      expect(selectedFileExtensionForImport(mdd), '.mdd');
    });

    test('allows a single extensionless file as an mdx candidate', () {
      final candidate = XFile('content-picker-cache');

      expect(selectMdxFileForImport([candidate]), same(candidate));
      expect(
        ensureFileExtensionForImport(
          displayFileNameForImport(candidate),
          '.mdx',
        ),
        'content-picker-cache.mdx',
      );
    });

    test('rejects a standalone mdd resource file', () {
      final mdd = XFile('daijisen.mdd');

      expect(selectMdxFileForImport([mdd]), isNull);
    });

    test('repairs common utf8 decoded as latin1 mojibake', () {
      final mojibakeKana = latin1.decode(utf8.encode('うえる'));

      expect(repairCommonMojibake('ï¼»pronunciationï¼½'), '［pronunciation］');
      expect(repairCommonMojibake(mojibakeKana), 'うえる');
    });
  });
}
