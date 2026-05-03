import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../data/models/dictionary_entry.dart';
import '../../shared/services/app_messenger.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';
import 'dictionary_providers.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dictionaryControllerProvider, (previous, next) {
      final state = next.asData?.value;
      if (state == null) {
        return;
      }

      if (state.errorMessage case final message?) {
        AppMessenger.showError(
          context,
          context.l10n.dictionaryOperationFailed(message),
        );
      }

      final importedName = state.lastImportedName;
      if (importedName != null && importedName.isNotEmpty) {
        AppMessenger.showSuccess(
          context,
          context.l10n.dictionaryImportSuccess(importedName),
        );
        ref.read(dictionaryControllerProvider.notifier).clearImportNotice();
      }
    });

    final asyncState = ref.watch(dictionaryControllerProvider);
    final l10n = context.l10n;

    return asyncState.when(
      loading: () => PageFrame(
        storageId: 'dictionary',
        title: l10n.dictionaryTitle,
        subtitle: l10n.dictionarySubtitle,
        children: const [SizedBox(height: 280, child: AppLoadingView())],
      ),
      error: (error, stackTrace) => PageFrame(
        storageId: 'dictionary',
        title: l10n.dictionaryTitle,
        subtitle: l10n.dictionarySubtitle,
        children: [AppErrorView(message: error.toString())],
      ),
      data: (state) => _DictionaryContent(
        state: state,
        searchController: _searchController,
        onSearch: (query) {
          final normalizedQuery = query.trim();
          if (normalizedQuery.isNotEmpty &&
              normalizedQuery != _searchController.text) {
            _searchController.value = TextEditingValue(
              text: normalizedQuery,
              selection: TextSelection.collapsed(
                offset: normalizedQuery.length,
              ),
            );
          }
          ref.read(dictionaryControllerProvider.notifier).search(query);
        },
      ),
    );
  }
}

class _DictionaryContent extends StatelessWidget {
  const _DictionaryContent({
    required this.state,
    required this.searchController,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasAnySource = state.hasEnabledDictionary;

    return PageFrame(
      storageId: 'dictionary',
      title: l10n.dictionaryTitle,
      subtitle: l10n.dictionarySubtitle,
      children: [
        if (!state.isSupported)
          SectionCard(
            title: l10n.dictionaryUnsupportedTitle,
            icon: Icons.info_outline_rounded,
            children: [Text(l10n.dictionaryUnsupportedMessage)],
          ),
        _SearchSection(
          state: state,
          controller: searchController,
          onSearch: onSearch,
        ),
        if (!hasAnySource && state.query.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: Theme.of(context).spacing.md),
            child: AppEmptyState(
              title: l10n.dictionaryEmptyTitle,
              message: l10n.dictionaryNoEnabledDictionaries,
            ),
          )
        else
          _TabbedResults(state: state, onSearch: onSearch),
      ],
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.state,
    required this.controller,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.dictionarySearchTitle,
      icon: Icons.manage_search_rounded,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: state.hasEnabledDictionary,
                decoration: InputDecoration(
                  labelText: l10n.dictionarySearchLabel,
                  hintText: l10n.dictionarySearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: onSearch,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: state.hasEnabledDictionary
                  ? () => onSearch(controller.text)
                  : null,
              icon: state.isSearching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.dictionarySearchButton),
            ),
          ],
        ),
        if (!state.hasEnabledDictionary) ...[
          const SizedBox(height: 12),
          Text(
            l10n.dictionaryNoEnabledDictionaries,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _TabbedResults extends ConsumerWidget {
  const _TabbedResults({required this.state, required this.onSearch});

  final DictionaryState state;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final entriesBySource = state.result.entriesBySource;

    if (state.isSearching) {
      return const SizedBox(height: 180, child: AppLoadingView());
    }

    if (state.result.query.isEmpty) {
      return SectionCard(
        title: l10n.dictionaryResultsTitle,
        icon: Icons.article_outlined,
        children: [Text(l10n.dictionaryResultsPlaceholder)],
      );
    }

    if (entriesBySource.isEmpty) {
      return _NoResults(result: state.result, onSearch: onSearch);
    }

    final sourceKeys = entriesBySource.keys.toList();
    final safeIndex = state.selectedSourceIndex.clamp(0, sourceKeys.length - 1);
    final selectedKey = sourceKeys[safeIndex];
    final entriesForSource = entriesBySource[selectedKey]!;
    final safeEntryIndex = state.selectedEntryIndex.clamp(
      0,
      entriesForSource.length - 1,
    );
    final currentEntry = entriesForSource[safeEntryIndex];

    return SectionCard(
      title: '${l10n.dictionaryResultsTitle} (${state.result.entries.length})',
      icon: Icons.article_outlined,
      children: [
        // Source selector chips
        Padding(
          padding: EdgeInsets.only(bottom: spacing.sm),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < sourceKeys.length; i++)
                ChoiceChip(
                  label: Text(
                    '${sourceKeys[i]} (${entriesBySource[sourceKeys[i]]!.length})',
                  ),
                  selected: i == safeIndex,
                  onSelected: (_) {
                    ref
                        .read(dictionaryControllerProvider.notifier)
                        .selectSource(i);
                  },
                ),
            ],
          ),
        ),
        // Entry index chips (only if >1 entry in current source)
        if (entriesForSource.length > 1) ...[
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: Row(
              children: [
                Text(
                  '${l10n.dictionaryResultsTitle}: ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < entriesForSource.length; i++)
                          Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                '${i + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: i == safeEntryIndex
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(dictionaryControllerProvider.notifier)
                                    .selectEntry(i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Current entry card
        _EntryCard(entry: currentEntry, onSearch: onSearch),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.result, required this.onSearch});

  final DictionarySearchResult result;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.dictionaryResultsTitle,
      icon: Icons.article_outlined,
      children: [
        Text(l10n.dictionaryNoResults(result.query)),
        if (result.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.dictionarySuggestionsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in result.suggestions)
                InputChip(
                  label: Text(suggestion),
                  onPressed: () => onSearch(suggestion),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onSearch});

  final DictionaryEntry entry;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = theme.spacing;
    final radii = theme.radii;

    return Container(
      margin: EdgeInsets.only(bottom: spacing.md),
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(radii.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.word,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                entry.sourceDictionary,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (entry.isRedirected) ...[
            SizedBox(height: spacing.xs),
            Text(
              '${entry.word} -> ${entry.resolvedWord}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: spacing.md),
          _MdictWebView(
            html: entry.definitionHtml,
            sourceDictionary: entry.sourceDictionary,
            onSearch: onSearch,
          ),
        ],
      ),
    );
  }
}

class _MdictWebView extends StatefulWidget {
  const _MdictWebView({
    required this.html,
    required this.sourceDictionary,
    required this.onSearch,
  });

  final String html;
  final String sourceDictionary;
  final ValueChanged<String> onSearch;

  @override
  State<_MdictWebView> createState() => _MdictWebViewState();
}

class _MdictWebViewState extends State<_MdictWebView> {
  static const _minHeight = 160.0;
  static const _maxHeight = 5000.0;

  InAppWebViewController? _controller;
  double _height = 360;

  @override
  void didUpdateWidget(covariant _MdictWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _height = 360;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: InAppWebView(
        key: ValueKey(widget.html),
        initialData: InAppWebViewInitialData(
          data: _buildMdictDocument(context, widget.html),
          baseUrl: WebUri('https://kotoba-kit.local/'),
          encoding: 'utf8',
          mimeType: 'text/html',
        ),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          javaScriptEnabled: true,
          supportZoom: false,
          useShouldOverrideUrlLoading: true,
          verticalScrollBarEnabled: false,
          horizontalScrollBarEnabled: false,
          disableHorizontalScroll: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          controller.addJavaScriptHandler(
            handlerName: 'lunaSearchWord',
            callback: (arguments) {
              final word = arguments.isEmpty ? null : arguments.first;
              if (word is String && word.trim().isNotEmpty) {
                widget.onSearch(word.trim());
              }
            },
          );
          controller.addJavaScriptHandler(
            handlerName: 'lunaResize',
            callback: (arguments) {
              final value = arguments.isEmpty ? null : arguments.first;
              final height = value is num
                  ? value.toDouble()
                  : double.tryParse(value.toString());
              if (height != null) {
                _setContentHeight(height);
              }
            },
          );
        },
        onLoadStop: (controller, url) {
          _syncContentHeight(controller);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final linkedWord = _lookupWordFromUrl(
            navigationAction.request.url?.toString(),
          );
          if (linkedWord != null) {
            widget.onSearch(linkedWord);
          }
          return NavigationActionPolicy.CANCEL;
        },
      ),
    );
  }

  Future<void> _syncContentHeight([InAppWebViewController? controller]) async {
    final webView = controller ?? _controller;
    if (webView == null || !mounted) {
      return;
    }

    final value = await webView.evaluateJavascript(
      source: '''
(() => {
  const body = document.body;
  const html = document.documentElement;
  return Math.ceil(Math.max(
    body ? body.scrollHeight : 0,
    body ? body.offsetHeight : 0,
    html ? html.clientHeight : 0,
    html ? html.scrollHeight : 0,
    html ? html.offsetHeight : 0
  ));
})()
''',
    );
    final nextHeight = double.tryParse(value.toString());
    if (nextHeight == null || !mounted) {
      return;
    }

    _setContentHeight(nextHeight);
  }

  void _setContentHeight(double height) {
    if (!mounted) {
      return;
    }

    final clamped = height.clamp(_minHeight, _maxHeight);
    if ((clamped - _height).abs() > 4) {
      setState(() {
        _height = clamped;
      });
    }
  }
}

String? _lookupWordFromUrl(String? url) {
  if (url == null) {
    return null;
  }

  final decoded = Uri.decodeFull(url).trim();
  if (decoded.isEmpty || decoded.startsWith('#')) {
    return null;
  }

  for (final scheme in ['entry://', 'mdict://', 'bword://']) {
    if (decoded.startsWith(scheme)) {
      return decoded.substring(scheme.length).replaceFirst(RegExp(r'^/+'), '');
    }
  }

  // Recognize Weblio content page links
  final weblioMatch = RegExp(
    r'^https?://www\.weblio\.jp/content/(.+)$',
  ).firstMatch(decoded);
  if (weblioMatch != null) {
    return Uri.decodeComponent(weblioMatch.group(1)!);
  }

  // Recognize Jisho search/word links
  final jishoMatch = RegExp(
    r'^https?://jisho\.org/(?:search|word)/(.+)$',
  ).firstMatch(decoded);
  if (jishoMatch != null) {
    final word = Uri.decodeComponent(jishoMatch.group(1)!);
    // Jisho /word/ paths may have additional segments
    return word.split('/').first;
  }

  if (decoded.startsWith('http://') ||
      decoded.startsWith('https://') ||
      decoded.startsWith('data:') ||
      decoded.startsWith('javascript:') ||
      decoded.startsWith('mailto:')) {
    return null;
  }

  return decoded.replaceFirst(RegExp(r'^/+'), '');
}

String _buildMdictDocument(BuildContext context, String value) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textStyle = theme.textTheme.bodyMedium;
  final body = _prepareMdictHtml(value);
  final foreground = _cssColor(scheme.onSurface);
  final muted = _cssColor(scheme.onSurfaceVariant);
  final primary = _cssColor(scheme.primary);
  final surface = _cssColor(scheme.surfaceContainerHighest);
  final fontSize = textStyle?.fontSize ?? 14;
  final fontFamily = _cssString(
    textStyle?.fontFamily ?? 'system-ui, "Yu Gothic UI", "Meiryo", sans-serif',
  );

  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      background: transparent;
      color: $foreground;
      font-family: $fontFamily;
      font-size: ${fontSize}px;
      line-height: 1.62;
      letter-spacing: 0;
      overflow-wrap: anywhere;
      word-break: normal;
    }
    body {
      box-sizing: border-box;
      width: 100%;
      overflow-x: hidden;
    }
    #luna_dict_internal_view {
      background: transparent;
    }
    h1, h2, h3, h4 {
      margin: 0 0 14px;
      color: $foreground;
      line-height: 1.25;
      font-weight: 700;
    }
    h3 {
      font-size: 1.28rem;
    }
    p, div, section {
      max-width: 100%;
    }
    p {
      margin: 0 0 10px;
    }
    a {
      color: $primary;
      text-decoration: underline;
      cursor: pointer;
    }
    k, .mdict-key {
      color: $primary;
    }
    v, .mdict-sense-number {
      color: $primary;
      font-weight: 700;
      padding-right: 0.25em;
    }
    .hinshi {
      color: $muted;
      font-weight: 600;
    }
    .description {
      display: block;
    }
    img, video, audio {
      max-width: 100%;
      height: auto;
    }
    table {
      max-width: 100%;
      border-collapse: collapse;
      background: color-mix(in srgb, $surface 32%, transparent);
    }
    td, th {
      padding: 6px 8px;
      border: 1px solid color-mix(in srgb, $muted 28%, transparent);
      vertical-align: top;
    }
    br {
      line-height: 1.62;
    }
    .element-hover {
      outline: 2px dashed #ffd700 !important;
      outline-offset: 2px !important;
    }
    .hightlight {
      background-color: yellow;
      outline: 2px solid #ffd700 !important;
      outline-offset: 2px !important;
    }
    .hightlight2 {
      background-color: yellow;
    }
  </style>
  <script>
    var lastmusicplayer = false;

    function luna_post_resize() {
      const body = document.body;
      const html = document.documentElement;
      const height = Math.ceil(Math.max(
        body ? body.scrollHeight : 0,
        body ? body.offsetHeight : 0,
        html ? html.clientHeight : 0,
        html ? html.scrollHeight : 0,
        html ? html.offsetHeight : 0
      ));
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('lunaResize', height);
      }
    }

    function safe_mdict_search_word(word) {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('lunaSearchWord', word);
      }
    }

    function mdict_play_sound(ext, b64) {
      const music = new Audio();
      music.src = 'data:' + ext + ';base64,' + b64;
      if (lastmusicplayer !== false) {
        lastmusicplayer.pause();
      }
      lastmusicplayer = music;
      music.play();
    }

    function replacelongvarsrcs(varval, varname) {
      const type = varval[0];
      const elements = document.querySelectorAll('[' + type + '="' + varname + '"]');
      for (let i = 0; i < elements.length; i++) {
        elements[i][type] = 'data:' + varval[1] + ';base64,' + varval[2];
      }
    }

    function clear_hightlight() {
      for (const klass of ['hightlight', 'hightlight2', 'element-hover']) {
        while (true) {
          const elements = document.getElementsByClassName(klass);
          if (elements.length === 0) break;
          elements[0].classList.remove(klass);
        }
      }
    }

    document.addEventListener('click', function(e) {
      const target = e.target.closest('a');
      if (!target) return;
      const href = target.getAttribute('href') || '';
      if (href.startsWith('entry://')) {
        e.preventDefault();
        e.stopPropagation();
        safe_mdict_search_word(decodeURIComponent(href.substring(8)));
      }
    }, true);

    window.addEventListener('load', function() {
      luna_post_resize();
      setTimeout(luna_post_resize, 80);
      setTimeout(luna_post_resize, 320);
    });

    if (window.ResizeObserver) {
      const observer = new ResizeObserver(luna_post_resize);
      document.addEventListener('DOMContentLoaded', function() {
        observer.observe(document.body);
      });
    }
  </script>
</head>
<body>
<div id="luna_dict_internal_view">
$body
</div>
</body>
</html>
''';
}

String _prepareMdictHtml(String value) {
  if (RegExp(r'<[A-Za-z][^>]*>').hasMatch(value)) {
    return value;
  }

  return value
      .split('\n')
      .map((line) => const HtmlEscape().convert(line.trimRight()))
      .join('<br>');
}

String _cssColor(Color color) {
  final alpha = color.a;
  final red = (color.r * 255).round();
  final green = (color.g * 255).round();
  final blue = (color.b * 255).round();

  if (alpha >= 1) {
    return 'rgb($red, $green, $blue)';
  }

  return 'rgba($red, $green, $blue, ${alpha.toStringAsFixed(3)})';
}

String _cssString(String value) {
  if (value.contains(',')) {
    return value;
  }

  return '"${value.replaceAll('"', r'\"')}"';
}
