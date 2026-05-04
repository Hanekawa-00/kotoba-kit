import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_kit/src/app/bootstrap.dart';
import 'package:kotoba_kit/src/data/models/dictionary_config.dart';
import 'package:kotoba_kit/src/data/models/dictionary_entry.dart';
import 'package:kotoba_kit/src/data/models/online_dictionary_config.dart';
import 'package:kotoba_kit/src/data/repositories/dictionary_repository.dart';
import 'package:kotoba_kit/src/data/services/online_sources/online_dictionary_source.dart';
import 'package:kotoba_kit/src/core/settings/app_settings.dart';
import 'package:kotoba_kit/src/core/settings/settings_providers.dart';
import 'package:kotoba_kit/src/core/settings/settings_repository.dart';
import 'package:kotoba_kit/src/features/dictionary/dictionary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders the dictionary workspace first', (tester) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lookup-desktop-side-panel')),
      findsOneWidget,
    );
    expect(find.text('Word'), findsOneWidget);
  });

  testWidgets('mobile top-level pages keep bottom navigation', (tester) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Lookup'), findsWidgets);
  });

  testWidgets('mobile lookup keeps search fixed above visible results', (
    tester,
  ) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    final searchBar = find.byKey(const ValueKey('lookup-mobile-search-bar'));
    final results = find.byKey(
      const PageStorageKey<String>('lookup-mobile-results'),
    );

    expect(searchBar, findsOneWidget);
    expect(results, findsOneWidget);
    expect(
      tester.getBottomLeft(searchBar).dy,
      lessThanOrEqualTo(tester.getTopLeft(results).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile lookup search assist scrolls and can be dismissed', (
    tester,
  ) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final assist = find.byKey(const ValueKey('lookup-search-assist-list'));
    final assistScroll = find.byKey(
      const ValueKey('lookup-search-assist-scroll'),
    );
    expect(assist, findsOneWidget);
    expect(assistScroll, findsOneWidget);
    expect(tester.getSize(assist).height, lessThanOrEqualTo(236));

    await tester.fling(assistScroll, const Offset(0, -120), 500);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const PageStorageKey<String>('lookup-mobile-results')),
    );
    await tester.pumpAndSettle();

    expect(assist, findsNothing);
  });

  testWidgets('compact mobile lookup avoids bottom overflow with assist open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final assist = find.byKey(const ValueKey('lookup-search-assist-list'));
    expect(assist, findsOneWidget);
    expect(tester.getSize(assist).height, lessThanOrEqualTo(172));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop lookup uses side panel and reading column', (
    tester,
  ) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lookup-desktop-side-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('lookup-desktop-588')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile settings subpage hides bottom navigation', (
    tester,
  ) async {
    _setMobileViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
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

  // Components gallery removed
  // testWidgets('mobile component gallery adapts to narrow screens', (
  //   tester,
  // ) async {
  //   _setMobileViewport(tester);
  //
  //   await tester.pumpWidget(_buildTestApp());
  //
  //   await tester.pumpAndSettle();
  //   await tester.tap(find.text('Components'));
  //   await tester.pump(const Duration(milliseconds: 300));
  //
  //   expect(find.text('Components'), findsWidgets);
  //   expect(find.byType(NavigationBar), findsOneWidget);
  //   expect(tester.takeException(), isNull);
  // });

  testWidgets('desktop settings keeps reset only in content', (tester) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
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
    await tester.tap(find.text('Settings').last);
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
    await tester.tap(find.text('Settings').last);
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
    await tester.tap(find.text('Settings').last);
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
  Future<List<String>> suggest(
    List<DictionaryConfig> configs,
    String query,
  ) async {
    return const [];
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

  @override
  Future<DictionarySearchResult> searchOnline(
    OnlineDictionarySource source,
    String query,
  ) async {
    return DictionarySearchResult(
      query: query,
      entries: const [],
      suggestions: const [],
    );
  }

  @override
  Future<List<OnlineDictionaryConfig>> loadOnlineConfigs() async => const [
    OnlineDictionaryConfig(id: 'jisho', name: 'Jisho', enabled: true),
  ];

  @override
  Future<void> saveOnlineConfigs(List<OnlineDictionaryConfig> configs) async {}

  @override
  Future<List<OnlineDictionaryConfig>> setOnlineEnabled(
    List<OnlineDictionaryConfig> configs,
    String id,
    bool enabled,
  ) async {
    return configs;
  }

  @override
  Future<List<String>> loadSearchHistory() async => const [
    '食べる',
    '食べ物',
    '食堂',
    '見る',
    '見える',
    '行く',
    '来る',
    'する',
    '読む',
    '書く',
    '話す',
    '聞く',
    '飲む',
    '買う',
    '帰る',
  ];

  @override
  Future<List<String>> saveSearchHistory(List<String> history) async {
    return history;
  }
}
