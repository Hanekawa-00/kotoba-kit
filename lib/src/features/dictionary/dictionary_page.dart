import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../data/models/dictionary_entry.dart';
import '../../shared/services/app_messenger.dart';
import '../../shared/widgets/app_state_views.dart';
import 'dictionary_providers.dart';
import 'mdict_web_view.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_handleSearchFocusChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChanged() {
    setState(() {});
  }

  void _dismissSearchFocus() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
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

    return asyncState.when(
      loading: () => const _LoadingLookupPage(),
      error: (error, stackTrace) => _ErrorLookupPage(message: error.toString()),
      data: (state) => _LookupWorkspace(
        state: state,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        searchHasFocus: _searchFocusNode.hasFocus,
        onDismissSearchFocus: _dismissSearchFocus,
        onDraftChanged: (query) {
          ref.read(dictionaryControllerProvider.notifier).updateDraft(query);
        },
        onSearch: (query) {
          _dismissSearchFocus();
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

class _LoadingLookupPage extends StatelessWidget {
  const _LoadingLookupPage();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      bottom: false,
      child: Center(child: AppLoadingView()),
    );
  }
}

class _ErrorLookupPage extends StatelessWidget {
  const _ErrorLookupPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(Theme.of(context).spacing.lg),
        child: AppErrorView(message: message),
      ),
    );
  }
}

class _LookupWorkspace extends StatelessWidget {
  const _LookupWorkspace({
    required this.state,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHasFocus,
    required this.onDismissSearchFocus,
    required this.onDraftChanged,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool searchHasFocus;
  final VoidCallback onDismissSearchFocus;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktop = constraints.maxWidth >= 900;
        if (useDesktop) {
          return _DesktopLookupLayout(
            state: state,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            searchHasFocus: searchHasFocus,
            onDismissSearchFocus: onDismissSearchFocus,
            onDraftChanged: onDraftChanged,
            onSearch: onSearch,
          );
        }

        return _MobileLookupLayout(
          state: state,
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          searchHasFocus: searchHasFocus,
          onDismissSearchFocus: onDismissSearchFocus,
          onDraftChanged: onDraftChanged,
          onSearch: onSearch,
        );
      },
    );
  }
}

class _MobileLookupLayout extends StatelessWidget {
  const _MobileLookupLayout({
    required this.state,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHasFocus,
    required this.onDismissSearchFocus,
    required this.onDraftChanged,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool searchHasFocus;
  final VoidCallback onDismissSearchFocus;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).spacing;

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          _TopSearchBar(
            state: state,
            controller: searchController,
            focusNode: searchFocusNode,
            showAssist: searchHasFocus,
            onDraftChanged: onDraftChanged,
            onSearch: onSearch,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismissSearchFocus,
              child: Padding(
                key: const PageStorageKey<String>('lookup-mobile-results'),
                padding: EdgeInsets.fromLTRB(
                  spacing.lg,
                  spacing.md,
                  spacing.lg,
                  spacing.xxl,
                ),
                child: _ResultPane(state: state, onSearch: onSearch),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLookupLayout extends StatelessWidget {
  const _DesktopLookupLayout({
    required this.state,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHasFocus,
    required this.onDismissSearchFocus,
    required this.onDraftChanged,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool searchHasFocus;
  final VoidCallback onDismissSearchFocus;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).spacing;

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing.xl, spacing.lg, spacing.xl, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 316,
              child: _LookupSidePanel(
                state: state,
                controller: searchController,
                focusNode: searchFocusNode,
                showAssist: searchHasFocus,
                onDraftChanged: onDraftChanged,
                onSearch: onSearch,
              ),
            ),
            SizedBox(width: spacing.lg),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onDismissSearchFocus,
                    child: Padding(
                      key: ValueKey('lookup-desktop-${constraints.maxWidth.toInt()}'),
                      padding: EdgeInsets.only(bottom: spacing.xxl),
                      child: _ResultPane(state: state, onSearch: onSearch),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.showAssist,
    required this.onDraftChanged,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showAssist;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final assistMaxHeight = _searchAssistMaxHeight(context);

    return DecoratedBox(
      key: const ValueKey('lookup-mobile-search-bar'),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.98),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          spacing.md,
          spacing.lg,
          spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SearchRow(
              state: state,
              controller: controller,
              focusNode: focusNode,
              onDraftChanged: onDraftChanged,
              onSearch: onSearch,
              compact: true,
            ),
            if (showAssist &&
                _searchAssistItems(state, controller.text).isNotEmpty) ...[
              SizedBox(height: spacing.sm),
              _SearchAssistList(
                state: state,
                query: controller.text,
                onSearch: onSearch,
                maxItems: 18,
                maxHeight: assistMaxHeight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LookupSidePanel extends ConsumerWidget {
  const _LookupSidePanel({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.showAssist,
    required this.onDraftChanged,
    required this.onSearch,
  });

  final DictionaryState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showAssist;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final entriesBySource = state.result.entriesBySource;
    final sourceKeys = entriesBySource.keys.toList();

    return DecoratedBox(
      key: const ValueKey('lookup-desktop-side-panel'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              l10n.dictionaryTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              l10n.dictionarySubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.lg),
            _SearchRow(
              state: state,
              controller: controller,
              focusNode: focusNode,
              onDraftChanged: onDraftChanged,
              onSearch: onSearch,
              compact: false,
            ),
            if (showAssist &&
                _searchAssistItems(state, controller.text).isNotEmpty) ...[
              SizedBox(height: spacing.md),
              _SearchAssistList(
                state: state,
                query: controller.text,
                onSearch: onSearch,
                maxItems: 18,
                maxHeight: 236,
              ),
            ],
            if (sourceKeys.isNotEmpty) ...[
              SizedBox(height: spacing.xl),
              Text(
                l10n.dictionaryResultsTitle,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: spacing.sm),
              for (var i = 0; i < sourceKeys.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xs),
                  child: ChoiceChip(
                    label: Text(
                      '${sourceKeys[i]} (${entriesBySource[sourceKeys[i]]!.length})',
                    ),
                    selected:
                        i ==
                        state.selectedSourceIndex
                            .clamp(0, sourceKeys.length - 1)
                            .toInt(),
                    onSelected: (_) {
                      ref
                          .read(dictionaryControllerProvider.notifier)
                          .selectSource(i);
                    },
                  ),
                ),
            ],
            if (state.searchHistory.isNotEmpty) ...[
              SizedBox(height: spacing.xl),
              Text(
                l10n.dictionaryHistoryTitle,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: spacing.sm),
              for (final item in state.searchHistory.take(10))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded),
                  title: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSearch(item),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.onDraftChanged,
    required this.onSearch,
    required this.compact,
  });

  final DictionaryState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSearch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = Theme.of(context).spacing;
    final input = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: state.hasEnabledDictionary,
      decoration: InputDecoration(
        labelText: l10n.dictionarySearchLabel,
        hintText: l10n.dictionarySearchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
      ),
      textInputAction: TextInputAction.search,
      onChanged: onDraftChanged,
      onSubmitted: onSearch,
    );
    final button = FilledButton(
      onPressed: state.hasEnabledDictionary
          ? () => onSearch(controller.text)
          : null,
      child: state.isSearching
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              compact
                  ? Icons.arrow_forward_rounded
                  : Icons.manage_search_rounded,
            ),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: input),
          SizedBox(width: spacing.sm),
          SizedBox.square(dimension: 48, child: button),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        input,
        SizedBox(height: spacing.sm),
        FilledButton.icon(
          onPressed: state.hasEnabledDictionary
              ? () => onSearch(controller.text)
              : null,
          icon: state.isSearching
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.manage_search_rounded),
          label: Text(l10n.dictionarySearchButton),
        ),
      ],
    );
  }
}

class _SearchAssistList extends StatelessWidget {
  const _SearchAssistList({
    required this.state,
    required this.query,
    required this.onSearch,
    required this.maxItems,
    required this.maxHeight,
  });

  final DictionaryState state;
  final String query;
  final ValueChanged<String> onSearch;
  final int maxItems;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _searchAssistItems(state, query).take(maxItems).toList();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final height = (items.length * 38.0 + theme.spacing.xs * 2)
        .clamp(0.0, maxHeight)
        .toDouble();

    return DecoratedBox(
      key: const ValueKey('lookup-search-assist-list'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(theme.radii.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: SizedBox(
        height: height,
        child: ListView(
          key: const ValueKey('lookup-search-assist-scroll'),
          padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
          children: items
              .map(
                (item) => SizedBox(
                  height: 38,
                  child: _SearchAssistTile(
                    item: item,
                    onSearch: onSearch,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SearchAssistTile extends StatelessWidget {
  const _SearchAssistTile({required this.item, required this.onSearch});

  final _SearchAssistItem item;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onSearch(item.value),
      borderRadius: BorderRadius.circular(theme.radii.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
        child: Row(
            children: [
              Icon(
                item.fromHistory
                    ? Icons.history_rounded
                    : Icons.manage_search_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
    );
  }
}

List<_SearchAssistItem> _searchAssistItems(
  DictionaryState state,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  final items = <_SearchAssistItem>[];
  final seen = <String>{};

  void add(String value, {required bool fromHistory}) {
    final trimmed = value.trim();
    final key = trimmed.toLowerCase();
    if (trimmed.isEmpty || seen.contains(key)) {
      return;
    }
    items.add(_SearchAssistItem(trimmed, fromHistory: fromHistory));
    seen.add(key);
  }

  if (normalized.isEmpty) {
    for (final item in state.searchHistory) {
      add(item, fromHistory: true);
    }
  } else {
    for (final item in state.searchHistory.where(
      (item) => item.toLowerCase().contains(normalized),
    )) {
      add(item, fromHistory: true);
    }
    for (final item in state.draftSuggestions) {
      add(item, fromHistory: state.searchHistory.contains(item));
    }
    for (final item in state.searchHistory) {
      add(item, fromHistory: true);
    }
  }

  return items;
}

class _SearchAssistItem {
  const _SearchAssistItem(this.value, {required this.fromHistory});

  final String value;
  final bool fromHistory;
}

double _searchAssistMaxHeight(BuildContext context) {
  final media = MediaQuery.of(context);
  final availableHeight = media.size.height - media.viewInsets.bottom;
  if (availableHeight < 460) {
    return 132;
  }
  if (availableHeight < 620) {
    return 172;
  }

  return 236;
}

class _ResultPane extends ConsumerWidget {
  const _ResultPane({required this.state, required this.onSearch});

  final DictionaryState state;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.isSupported) {
      return _MessagePanel(
        icon: Icons.info_outline_rounded,
        title: context.l10n.dictionaryUnsupportedTitle,
        message: context.l10n.dictionaryUnsupportedMessage,
      );
    }

    if (!state.hasEnabledDictionary && state.query.isNotEmpty) {
      return AppEmptyState(
        title: context.l10n.dictionaryEmptyTitle,
        message: context.l10n.dictionaryNoEnabledDictionaries,
      );
    }

    if (state.isSearching) {
      return const SizedBox(height: 220, child: AppLoadingView());
    }

    final entriesBySource = state.result.entriesBySource;
    if (state.result.query.isEmpty) {
      return _StartPanel(state: state, onSearch: onSearch);
    }

    if (entriesBySource.isEmpty) {
      return _NoResults(result: state.result, onSearch: onSearch);
    }

    final sourceKeys = entriesBySource.keys.toList();
    final safeSourceIndex = state.selectedSourceIndex
        .clamp(0, sourceKeys.length - 1)
        .toInt();
    final selectedSource = sourceKeys[safeSourceIndex];
    final entriesForSource = entriesBySource[selectedSource]!;
    final safeEntryIndex = state.selectedEntryIndex
        .clamp(0, entriesForSource.length - 1)
        .toInt();
    final currentEntry = entriesForSource[safeEntryIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sourceKeys.length > 1)
          Padding(
            padding: EdgeInsets.only(bottom: Theme.of(context).spacing.md),
            child: _SourceSwitcher(
              sourceKeys: sourceKeys,
              selectedIndex: safeSourceIndex,
              entriesBySource: state.result.entriesBySource,
              onSelected: (index) {
                ref
                    .read(dictionaryControllerProvider.notifier)
                    .selectSource(index);
              },
            ),
          ),
        Expanded(
          child: _ReadingPanel(
      entry: currentEntry,
      result: state.result,
      sourceKeys: sourceKeys,
      selectedSourceIndex: safeSourceIndex,
      entriesForSource: entriesForSource,
      selectedEntryIndex: safeEntryIndex,
      onSourceSelected: (index) {
        ref.read(dictionaryControllerProvider.notifier).selectSource(index);
      },
      onEntrySelected: (index) {
        ref.read(dictionaryControllerProvider.notifier).selectEntry(index);
      },
      onSearch: onSearch,
          ),
        ),
      ],
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.state, required this.onSearch});

  final DictionaryState state;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return _PanelShell(
      key: const ValueKey('lookup-reading-panel'),
      expand: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dictionaryResultsTitle,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: spacing.sm),
            Text(
              l10n.dictionaryResultsPlaceholder,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.searchHistory.isNotEmpty) ...[
              SizedBox(height: spacing.lg),
              Text(
                l10n.dictionaryHistoryTitle,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: spacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in state.searchHistory.take(12))
                    InputChip(
                      avatar: const Icon(Icons.history_rounded, size: 16),
                      label: Text(item),
                      onPressed: () => onSearch(item),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return _PanelShell(
      expand: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SourceErrors(errors: result.sourceErrors),
            Text(l10n.dictionaryNoResults(result.query)),
            if (result.suggestions.isNotEmpty) ...[
              SizedBox(height: spacing.md),
              Text(
                l10n.dictionarySuggestionsTitle,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: spacing.sm),
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
        ),
      ),
    );
  }
}

class _ReadingPanel extends StatelessWidget {
  const _ReadingPanel({
    required this.entry,
    required this.result,
    required this.sourceKeys,
    required this.selectedSourceIndex,
    required this.entriesForSource,
    required this.selectedEntryIndex,
    required this.onSourceSelected,
    required this.onEntrySelected,
    required this.onSearch,
  });

  final DictionaryEntry entry;
  final DictionarySearchResult result;
  final List<String> sourceKeys;
  final int selectedSourceIndex;
  final List<DictionaryEntry> entriesForSource;
  final int selectedEntryIndex;
  final ValueChanged<int> onSourceSelected;
  final ValueChanged<int> onEntrySelected;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;

    return _PanelShell(
      key: const ValueKey('lookup-reading-panel'),
      expand: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerMaxHeight = (constraints.maxHeight * 0.42)
              .clamp(76.0, 220.0)
              .toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: headerMaxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SourceErrors(errors: result.sourceErrors),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.word,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (entry.isRedirected) ...[
                                  SizedBox(height: spacing.xs),
                                  Text(
                                    '${entry.word} -> ${entry.resolvedWord}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Text(
                            entry.sourceDictionary,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (entriesForSource.length > 1) ...[
                        SizedBox(height: spacing.md),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) => ChoiceChip(
                              label: Text('${index + 1}'),
                              selected: index == selectedEntryIndex,
                              onSelected: (_) => onEntrySelected(index),
                            ),
                            separatorBuilder: (context, index) =>
                                SizedBox(width: spacing.xs),
                            itemCount: entriesForSource.length,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
              Expanded(
                child: MdictWebView(
                  html: entry.definitionHtml,
                  sourceDictionary: entry.sourceDictionary,
                  expand: true,
                  onSearch: onSearch,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SourceSwitcher extends StatelessWidget {
  const _SourceSwitcher({
    required this.sourceKeys,
    required this.selectedIndex,
    required this.entriesBySource,
    required this.onSelected,
  });

  final List<String> sourceKeys;
  final int selectedIndex;
  final Map<String, List<DictionaryEntry>> entriesBySource;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).spacing;

    return SizedBox(
      key: const ValueKey('lookup-source-switcher'),
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final source = sourceKeys[index];
          final count = entriesBySource[source]?.length ?? 0;
          return ChoiceChip(
            label: Text('$source · $count'),
            selected: index == selectedIndex,
            onSelected: (_) => onSelected(index),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: spacing.xs),
        itemCount: sourceKeys.length,
      ),
    );
  }
}

class _SourceErrors extends StatelessWidget {
  const _SourceErrors({required this.errors});

  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(theme.radii.md),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Text(
                  errors.entries
                      .map(
                        (item) => context.l10n.dictionarySourceFailed(
                          item.key,
                          item.value,
                        ),
                      )
                      .join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PanelShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                SizedBox(height: theme.spacing.xs),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({super.key, required this.child, this.expand = false});

  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(padding: EdgeInsets.all(theme.spacing.lg), child: child),
    );

    if (expand) {
      return SizedBox.expand(child: panel);
    }

    return panel;
  }
}
