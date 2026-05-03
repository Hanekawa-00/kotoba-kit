import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../data/models/dictionary_config.dart';
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
        onImport: () {
          ref.read(dictionaryControllerProvider.notifier).importDictionary();
        },
        onSearch: (query) {
          ref.read(dictionaryControllerProvider.notifier).search(query);
        },
        onToggle: (config, enabled) {
          ref
              .read(dictionaryControllerProvider.notifier)
              .setEnabled(config.id, enabled);
        },
        onDelete: (config) {
          ref
              .read(dictionaryControllerProvider.notifier)
              .deleteDictionary(config);
        },
      ),
    );
  }
}

class _DictionaryContent extends StatelessWidget {
  const _DictionaryContent({
    required this.state,
    required this.searchController,
    required this.onImport,
    required this.onSearch,
    required this.onToggle,
    required this.onDelete,
  });

  final DictionaryState state;
  final TextEditingController searchController;
  final VoidCallback onImport;
  final ValueChanged<String> onSearch;
  final void Function(DictionaryConfig config, bool enabled) onToggle;
  final ValueChanged<DictionaryConfig> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PageFrame(
      storageId: 'dictionary',
      title: l10n.dictionaryTitle,
      subtitle: l10n.dictionarySubtitle,
      trailing: FilledButton.icon(
        onPressed: state.isImporting || !state.isSupported ? null : onImport,
        icon: state.isImporting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(
          state.isImporting ? l10n.dictionaryImporting : l10n.dictionaryImport,
        ),
      ),
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
        _InstalledDictionariesSection(
          configs: state.configs,
          onToggle: onToggle,
          onDelete: onDelete,
        ),
        _SearchResultsSection(
          result: state.result,
          isSearching: state.isSearching,
        ),
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

class _InstalledDictionariesSection extends StatelessWidget {
  const _InstalledDictionariesSection({
    required this.configs,
    required this.onToggle,
    required this.onDelete,
  });

  final List<DictionaryConfig> configs;
  final void Function(DictionaryConfig config, bool enabled) onToggle;
  final ValueChanged<DictionaryConfig> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.dictionaryInstalledTitle,
      icon: Icons.library_books_outlined,
      children: [
        if (configs.isEmpty)
          AppEmptyState(
            title: l10n.dictionaryEmptyTitle,
            message: l10n.dictionaryEmptyMessage,
          )
        else
          for (final config in configs)
            _DictionaryTile(
              config: config,
              onToggle: (enabled) => onToggle(config, enabled),
              onDelete: () => onDelete(config),
            ),
      ],
    );
  }
}

class _DictionaryTile extends StatelessWidget {
  const _DictionaryTile({
    required this.config,
    required this.onToggle,
    required this.onDelete,
  });

  final DictionaryConfig config;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_rounded),
      title: Text(config.name),
      subtitle: Text(
        config.entryCount == null
            ? config.mdxPath
            : l10n.dictionaryEntryCount(config.entryCount!),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Switch(value: config.enabled, onChanged: onToggle),
          IconButton(
            tooltip: l10n.dictionaryDelete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.result,
    required this.isSearching,
  });

  final DictionarySearchResult result;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.dictionaryResultsTitle,
      icon: Icons.article_outlined,
      children: [
        if (isSearching)
          const SizedBox(height: 180, child: AppLoadingView())
        else if (result.query.isEmpty)
          Text(l10n.dictionaryResultsPlaceholder)
        else if (result.entries.isEmpty)
          _NoResults(result: result)
        else
          for (final entry in result.entries) _EntryCard(entry: entry),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.result});

  final DictionarySearchResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                InputChip(label: Text(suggestion)),
            ],
          ),
        ],
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final DictionaryEntry entry;

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
          SizedBox(height: spacing.md),
          SelectableText(
            _stripHtml(entry.definitionHtml),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s+'), '\n')
      .trim();
}
