# Kotoba Kit

[![CI](https://github.com/Hanekawa-00/kotoba-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/Hanekawa-00/kotoba-kit/actions/workflows/ci.yml)

> [中文说明](README_zh.md)

An offline-first Japanese dictionary and learning toolkit. Built on Flutter,
targeting all major platforms with a focus on reliable local dictionary lookup.

## Features

### Current

- **Local MDict lookup** — Import `.mdx`/`.mdd` dictionary files; exact match
  with prefix suggestions. Fully offline.
- **Online dictionary sources** — Weblio and Jisho lookup, fetched and rendered
  alongside local results. Togglable per source.
- **WebView rendering** — Dictionary entries are rendered as browser HTML with
  scoped CSS, entry cross-linking, and embedded audio/image support, following
  the LunaTranslator rendering pattern.
- **Multi-source results** — Search across local and online dictionaries in
  parallel. Results grouped by source with quick-switching chips.
- **Dictionary management** — Import, enable/disable, and delete dictionaries
  from Settings.
- **Material 3 theming** — Light/dark/system theme, color presets, OLED dark
  mode, compact density.
- **Cross-platform** — Windows (custom title bar), Linux, macOS, Android, iOS,
  Web. Responsive layout adapts between mobile bottom-nav and desktop sidebar.

### Planned

| Feature | Description |
|---|---|
| Japanese tokenizer | MeCab-based morphological analysis for word-boundary-aware lookup |
| Sentence practice | AI-assisted translation, multiple-choice, and free-form practice |
| Grammar library | Offline JLPT N5–N1 grammar reference with examples |
| TTS pronunciation | Three-tier speech synthesis (Gemini → Cloud → local fallback) |
| Visual vocabulary | Camera-based object/text detection with bounding boxes and dictionary lookup |
| Practice history | Persistent history with filtering and import/export |

See `docs/japanese-learning-app-design.md` for the full architecture and roadmap.

## Platform Support

| Platform | Status |
|---|---|
| Windows | Supported (custom window chrome) |
| Linux | Supported (custom window chrome) |
| macOS | Project generated |
| Android | Supported |
| iOS | Project generated |
| Web | Dictionary page works (local MDX stubbed, online sources available) |

## Quick Start

```bash
flutter pub get
flutter run -t lib/main_development.dart
```

Environment-specific entry points:

```bash
flutter run -t lib/main_development.dart
flutter run -t lib/main_staging.dart
flutter run -t lib/main_production.dart
```

Or via `--dart-define`:

```bash
flutter run --dart-define=APP_ENV=staging
flutter run --dart-define=APP_ENV=production --dart-define=APP_NAME=KotobaKit
```

## Commands

```bash
# Format, analyze, test
dart format lib test scripts
flutter analyze
flutter test

# Full local check
pwsh ./scripts/check.ps1

# Regenerate localization
flutter gen-l10n

# Generate a new feature module
dart run scripts/new_feature.dart <feature_name>

# Release builds
flutter build windows --release -t lib/main_production.dart
flutter build apk --release --split-per-abi -t lib/main_production.dart
flutter build web --release -t lib/main_production.dart
```

## Project Structure

```
lib/
  main*.dart                  # Entry points per environment
  l10n/                       # ARB localization files (en, zh)
  src/
    app/                      # App runner and MaterialApp bootstrap
    core/                     # Config, errors, logging, routing, theme,
                              #   settings, network (Dio), storage (Hive CE),
                              #   cache, platform, windowing
    data/
      models/                 # DictionaryConfig, DictionaryEntry,
                              #   OnlineDictionaryConfig
      repositories/           # DictionaryRepository + local/online persistence
      services/
        dictionary_service_*.dart   # MDX/MDD file parsing (IO + stub)
        online_sources/             # WeblioSource, JishoSource + LRU cache
    features/
      dictionary/             # Search page + providers
      home/                   # Dashboard
      settings/               # Preferences + dictionary management
      about/                  # App info
      components/             # Template component gallery (disabled)
    shared/                   # Reusable widgets (PageFrame, SectionCard,
                              #   AppShell, AppStateViews, ConfirmActionDialog)
```

## Architecture

- **State**: Riverpod 3.x — `AsyncNotifier` for dictionary state, providers for
  infrastructure injection.
- **Routing**: `go_router` with `StatefulShellRoute.indexedStack` — preserves
  scroll positions and widget state across tab switches.
- **Dictionary pipeline**: `DictionaryPage` → `DictionaryController` →
  `DictionaryRepository` → `DictionaryService` (local MDX) + `OnlineDictionarySource`
  (Weblio/Jisho) — parallel search, merged results → `InAppWebView` rendering.
- **Responsive**: 760px breakpoint — mobile bottom nav below, desktop sidebar above.
- **Theme**: Material 3 `ColorScheme.fromSeed` with custom `ThemeExtension` tokens
  (spacing, radii, motion).

## Design Documents

- `docs/japanese-learning-app-design.md` — Full product architecture and roadmap
- `docs/kotoba_kit_design_architecture.md` — Dictionary-specific design (MDX/MDD
  import, lookup pipeline, WebView rendering)
- `docs/architecture.md` — Template-level architecture (routing, state, data)
- `docs/design_system.md` — Design tokens and responsive rules
- `AGENTS.md` — AI agent and developer collaboration conventions

## License

MIT — see [LICENSE](LICENSE).
