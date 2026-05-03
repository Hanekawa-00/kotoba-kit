# Kotoba Kit Design And Architecture

Kotoba Kit is an offline-first Japanese dictionary and learning workspace. The
first product milestone is dependable local dictionary lookup, with learning
features built around the same local data foundation later.

This document supersedes the original template-level architecture for
dictionary work. The template architecture still describes app shell, routing,
theme, and shared infrastructure; this document describes the product-specific
design, domain boundaries, and implementation strategy.

## Principles

### Offline First

Local dictionary lookup is the highest-priority capability. Search, rendering,
and dictionary management must work without a network connection after import.

### Stand On Existing Work

Dictionary formats are old, irregular, and full of edge cases. Prefer studying
and borrowing proven implementation strategies from mature tools before
inventing a local design. Good reference systems include LunaTranslator,
GoldenDict, Yomitan, EBWin, and other established dictionary readers.

When a new compatibility issue appears, the default workflow is:

1. Reproduce with the actual dictionary file.
2. Inspect the raw MDX record and related MDD resources.
3. Compare behavior with a mature implementation.
4. Port the smallest robust strategy that matches this app's architecture.
5. Add a focused regression note or test when feasible.

### Separate Lookup From Rendering

MDict lookup and MDict rendering are different problems.

- Lookup answers: which record should be returned for a query?
- Rendering answers: how should the returned HTML, CSS, images, audio, links,
  and scripts behave?

Changing the parser does not necessarily improve visual fidelity. Rendering
compatibility should be solved in the rendering layer unless the raw record is
actually wrong or missing.

## Product Scope

### Current Scope

- Import local `.mdx` dictionaries.
- Copy same-name `.mdd` resources during import.
- Store imported dictionaries in the application support directory.
- Enable, disable, and delete dictionaries.
- Exact lookup with prefix suggestions.
- Resolve MDict `@@@LINK=...` redirects.
- Render dictionary records as browser HTML.
- Rewrite common MDict resource references before rendering.

### Near-Term Scope

- Better MDD resource coverage for images, CSS, fonts, and embedded audio.
- Dictionary-specific compatibility fixtures.
- Persistent import/index metadata.
- Search modes beyond exact and prefix lookup.
- Entry history and bookmarks.

### Out Of Scope For The MVP

- Cloud dictionary sync.
- Server-only lookup.
- User-generated dictionary editing.
- Perfect compatibility with every proprietary dictionary package.

## Architecture Overview

```text
User
  |
DictionaryPage
  |
DictionaryController (Riverpod)
  |
DictionaryRepository
  |
DictionaryService
  |-- MDX reader lifecycle
  |-- MDD resource reader lifecycle
  |-- link redirect resolution
  |-- HTML/resource repair
  |
DictionaryEntry
  |
Mdict WebView renderer
```

The UI should never directly read MDX/MDD files. Pages consume
`DictionarySearchResult` and render `DictionaryEntry` objects.

## Data Model

### DictionaryConfig

`DictionaryConfig` represents an imported dictionary:

- `id`: stable app-local identifier.
- `name`: display name, usually from MDX title metadata.
- `mdxPath`: copied MDX file in the app support directory.
- `mddPath`: copied same-name MDD file, when present.
- `importedAt`: import timestamp.
- `enabled`: whether this dictionary participates in search.
- `entryCount`: optional count reported by the reader.

### DictionaryEntry

`DictionaryEntry` represents one rendered result:

- `word`: the user's display/query word.
- `resolvedWord`: final target after redirect, when different.
- `definitionHtml`: repaired HTML ready for the renderer.
- `sourceDictionary`: display name of the dictionary.
- `redirectChain`: followed `@@@LINK` targets.

`definitionHtml` should already have resource references repaired where possible.
The renderer may still add a safe document wrapper and theme CSS.

## Lookup Pipeline

1. Trim the user query.
2. Search enabled dictionaries in repository order.
3. Locate exact MDX matches.
4. Read each matching record.
5. If the record starts with `@@@LINK=...`, recursively resolve the target.
6. Stop redirect traversal on depth limit or cycle detection.
7. Repair the final record's HTML and resources.
8. Return entries plus prefix suggestions when no exact match exists.

Redirect handling belongs in the lookup pipeline because it changes the record
identity before rendering.

## Rendering Pipeline

The renderer follows the LunaTranslator pattern: dictionary entries are browser
HTML, not Flutter widget trees.

1. Keep raw dictionary HTML as HTML.
2. Repair `href` and `src` attributes before rendering.
3. Inline local or MDD CSS when available.
4. Convert images, fonts, and audio from MDD into data URLs when available.
5. Convert `entry://...` links into internal lookup callbacks.
6. Wrap the result in a controlled HTML document.
7. Render with WebView/WebView2.
8. Use JavaScript bridge callbacks for lookup, audio, and height updates.

`flutter_html` is not appropriate as the primary renderer for MDict entries. It
is useful for simple HTML, but it does not behave like a browser for arbitrary
dictionary HTML/CSS and unknown tags.

## LunaTranslator-Inspired Details

LunaTranslator's relevant strategy is:

- Use a WebView HTML frame for dictionary output.
- Place dictionary content under `#luna_dict_internal_view`.
- Provide helper JavaScript functions such as `safe_mdict_search_word` and
  `mdict_play_sound`.
- Rewrite MDX record links and resources before rendering.
- Load MDD resources and turn them into inline CSS, data URLs, or JavaScript
  actions.
- Keep dictionary CSS isolated from the surrounding UI.

Kotoba Kit adopts the same shape while fitting Flutter:

- `InAppWebView` hosts the entry HTML.
- Flutter's JS handlers receive internal search and resize messages.
- Each entry is rendered in its own WebView, which naturally limits CSS bleed.
- The Dart service repairs MDict resources before creating `DictionaryEntry`.

## MDict Resource Handling

MDict packages commonly use:

- `.mdx`: keyword index and HTML/text records.
- `.mdd`: resource records, such as CSS, images, fonts, and audio.
- `@@@LINK=target`: record redirect.
- `entry://target`: internal dictionary link.
- `sound://target`: embedded audio reference.
- Relative `href` and `src` references to dictionary resources.

The service should try resources in this order:

1. Local file next to the imported MDX.
2. Same-name MDD record with normalized slash variants.
3. Original URL preserved when no local resource can be found.

Resource lookup should be tolerant of:

- `/path`, `\path`, `path`, and `./path`.
- Query strings and anchors after filenames.
- Case differences where the underlying reader supports them.

## Platform Strategy

### Windows

Windows uses WebView2 through `flutter_inappwebview_windows`. The development
environment needs NuGet available in `PATH` so plugin dependencies can be
downloaded during CMake/MSBuild.

### macOS

macOS uses the platform WebKit implementation through the same WebView package.
Plugin registrants must stay generated and committed when dependencies change.

### Web

The current local dictionary service is stubbed on web because browser sandboxing
does not match local MDX/MDD file lifecycle yet.

## Error Handling

Dictionary import and search errors should surface through
`DictionaryController` and `AppMessenger`. Low-level errors may throw in
`DictionaryService`, but UI pages should receive stable state.

When a dictionary is partially compatible:

- Preserve the original HTML when a resource cannot be found.
- Prefer degraded rendering over failing the whole entry.
- Log or expose actionable errors only when they help debugging.

## Version Management

- Keep parser and renderer dependencies pinned when compatibility matters.
- Commit generated plugin registrant changes with dependency changes.
- Avoid mixing experimental backend changes with renderer fixes in one pushed
  history.
- If an experiment is wrong but already committed locally, use clear revert or
  clean rebase before pushing.

## Testing And Validation

Run the normal Flutter checks after implementation:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build windows --debug -t lib\main_development.dart
```

For dictionary compatibility work, also verify manually with at least:

- A pure text entry.
- An entry containing `@@@LINK`.
- An entry containing custom tags such as `<k>` and `<v>`.
- An entry using linked CSS.
- An entry referencing MDD images or audio when available.

## Design Consequences

The app should treat dictionary rendering like a small browser surface embedded
inside a native shell. The shell owns navigation, settings, and application
state; the WebView owns dictionary HTML fidelity.

This keeps the Flutter UI clean while still respecting how real dictionary
packages are authored.
