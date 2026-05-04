import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'MDict WebView is configured as a fixed scrollable reading viewport',
    () {
      final source = File(
        'lib/src/features/dictionary/mdict_web_view.dart',
      ).readAsStringSync();

      expect(source, contains("ValueKey('mdict-reader-viewport')"));
      expect(source, contains('VerticalDragGestureRecognizer'));
      expect(source, contains('overflow-y: auto'));
      expect(source, contains('0.58'));
      expect(source, contains('0.68'));
    },
  );
}
