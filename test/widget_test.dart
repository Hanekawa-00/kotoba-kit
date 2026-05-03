import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/app/bootstrap.dart';
import 'package:kotoba_kit/src/data/models/dictionary_config.dart';
import 'package:kotoba_kit/src/data/models/dictionary_entry.dart';
import 'package:kotoba_kit/src/data/repositories/dictionary_repository.dart';
import 'package:kotoba_kit/src/core/settings/app_settings.dart';
import 'package:kotoba_kit/src/core/settings/settings_providers.dart';
import 'package:kotoba_kit/src/core/settings/settings_repository.dart';
import 'package:kotoba_kit/src/features/dictionary/dictionary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders the dictionary workspace first', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Dictionary'), findsWidgets);
    expect(find.text('Lookup'), findsOneWidget);
    expect(find.text('No dictionaries imported'), findsOneWidget);
  });

  testWidgets('mobile top-level pages keep bottom navigation', (tester) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dictionary'), findsWidgets);
  });

  testWidgets('mobile settings subpage hides bottom navigation', (
    tester,
  ) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('About'), 520);
    await Scrollable.ensureVisible(
      tester.element(find.text('About')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('mobile top-level back asks before exiting', (tester) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Press back again to exit'), findsOneWidget);
  });

  testWidgets('mobile component gallery adapts to narrow screens', (
    tester,
  ) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Components'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Components'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop settings keeps reset only in content', (tester) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -900),
      900,
    );
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsNothing);
    expect(find.text('Reset preferences'), findsOneWidget);
  });

  testWidgets('desktop subpage actions stay available after scrolling', (
    tester,
  ) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -900),
      900,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About').last);
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -900),
      900,
    );
    await tester.pumpAndSettle();

    expect(find.text('Back to settings'), findsOneWidget);
  });

  testWidgets('desktop keeps page scroll when leaving and returning', (
    tester,
  ) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -900),
      900,
    );
    await tester.pumpAndSettle();
    final settingsOffset = _pageScrollOffset(tester);

    expect(settingsOffset, greaterThan(0));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(_pageScrollOffset(tester), greaterThan(settingsOffset * 0.7));

    await tester.tap(find.text('About').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to settings'));
    await tester.pumpAndSettle();

    expect(_pageScrollOffset(tester), greaterThan(settingsOffset * 0.7));
  });
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
      dictionaryRepositoryProvider.overrideWithValue(
        _FakeDictionaryRepository(),
      ),
    ],
    child: const AppBootstrap(),
  );
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

double _pageScrollOffset(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byType(CustomScrollView),
    matching: find.byType(Scrollable),
  );

  return tester.state<ScrollableState>(scrollable).position.pixels;
}

class _FakeSettingsRepository implements AppSettingsRepository {
  AppSettings _settings = AppSettings.defaults();

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}

class _FakeDictionaryRepository implements DictionaryRepository {
  List<DictionaryConfig> _configs = const [];

  @override
  bool get isSupported => true;

  @override
  Future<void> deleteDictionary(
    List<DictionaryConfig> configs,
    DictionaryConfig config,
  ) async {
    _configs = configs.where((item) => item.id != config.id).toList();
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<DictionaryImportResult?> importDictionary() async => null;

  @override
  Future<List<DictionaryConfig>> loadConfigs() async => _configs;

  @override
  Future<void> saveConfigs(List<DictionaryConfig> configs) async {
    _configs = configs;
  }

  @override
  Future<DictionarySearchResult> search(
    List<DictionaryConfig> configs,
    String query,
  ) async {
    return DictionarySearchResult(
      query: query,
      entries: const [],
      suggestions: const [],
    );
  }

  @override
  Future<List<DictionaryConfig>> setEnabled(
    List<DictionaryConfig> configs,
    String id,
    bool enabled,
  ) async {
    _configs = configs;
    return _configs;
  }
}
