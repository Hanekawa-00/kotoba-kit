import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/llm_providers.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/practice_types.dart';
import '../providers/practice_providers.dart';

class PracticeWelcomeView extends ConsumerWidget {
  const PracticeWelcomeView({super.key, required this.state});

  final PracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final llmConfigured = ref.watch(llmProviderProvider) != null;
    final error = state.errorMessage;

    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumn = constraints.maxWidth >= 640;

              if (useTwoColumn) {
                return _DesktopLayout(
                  state: state,
                  llmConfigured: llmConfigured,
                  error: error,
                );
              }
              return _MobileLayout(
                state: state,
                llmConfigured: llmConfigured,
                error: error,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({
    required this.state,
    required this.llmConfigured,
    required String? this.error,
  });

  final PracticeState state;
  final bool llmConfigured;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(spacing.xl, spacing.xl, spacing.xl, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.lg),
              child: Card(
                color: scheme.errorContainer,
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Text(
                    error!,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SectionCard(
                  title: l10n.practiceModeLabel,
                  icon: Icons.edit_note_outlined,
                  children: [
                    _ModeCard(
                      icon: Icons.translate_outlined,
                      title: l10n.practiceModeTranslation,
                      subtitle: l10n.practiceModeTranslationDesc,
                      selected: state.gameMode == GameMode.translation,
                      onTap: () =>
                          controller.selectMode(GameMode.translation),
                    ),
                    SizedBox(height: spacing.sm),
                    _ModeCard(
                      icon: Icons.quiz_outlined,
                      title: l10n.practiceModeMultipleChoice,
                      subtitle: l10n.practiceModeMultipleChoiceDesc,
                      selected:
                          state.gameMode == GameMode.multipleChoice,
                      onTap: () =>
                          controller.selectMode(GameMode.multipleChoice),
                    ),
                    SizedBox(height: spacing.sm),
                    _ModeCard(
                      icon: Icons.edit_outlined,
                      title: l10n.practiceModeSentenceCheck,
                      subtitle: l10n.practiceModeSentenceCheckDesc,
                      selected:
                          state.gameMode == GameMode.sentenceCheck,
                      onTap: () =>
                          controller.selectMode(GameMode.sentenceCheck),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.lg),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SectionCard(
                      title: l10n.practiceDifficulty,
                      icon: Icons.speed_outlined,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<Difficulty>(
                            segments: [
                              for (final d in Difficulty.values)
                                ButtonSegment(
                                  value: d,
                                  label: Text(d.name.substring(1)),
                                ),
                            ],
                            selected: {state.difficulty},
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            onSelectionChanged: (value) {
                              controller.selectDifficulty(value.first);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    SectionCard(
                      title: l10n.practiceSentenceLength,
                      icon: Icons.short_text_outlined,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<SentenceLength>(
                            segments: [
                              ButtonSegment(
                                value: SentenceLength.short,
                                label: Text(
                                    l10n.practiceSentenceLengthShort),
                              ),
                              ButtonSegment(
                                value: SentenceLength.medium,
                                label: Text(
                                    l10n.practiceSentenceLengthMedium),
                              ),
                              ButtonSegment(
                                value: SentenceLength.long,
                                label: Text(
                                    l10n.practiceSentenceLengthLong),
                              ),
                            ],
                            selected: {state.sentenceLength},
                            onSelectionChanged: (value) {
                              controller
                                  .selectSentenceLength(value.first);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    FilledButton.icon(
                      onPressed: llmConfigured
                          ? () => controller.startNewTask()
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.practiceStartButton),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    if (!llmConfigured)
                      Padding(
                        padding: EdgeInsets.only(top: spacing.sm),
                        child: Text(
                          l10n.practiceNoApiKey,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xl),
          SectionCard(
            title: '',
            icon: Icons.menu_book_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _LinkTile(
                      icon: Icons.menu_book_outlined,
                      title: l10n.practiceGrammarTitle,
                      subtitle: l10n.practiceGrammarSubtitle,
                      onTap: () => context.push('/practice/grammar'),
                    ),
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: _LinkTile(
                      icon: Icons.history_rounded,
                      title: l10n.practiceHistoryTitle,
                      subtitle: l10n.practiceHistoryEmpty,
                      onTap: () => context.push('/practice/history'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({
    required this.state,
    required this.llmConfigured,
    required String? this.error,
  });

  final PracticeState state;
  final bool llmConfigured;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (error != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, 0),
            sliver: SliverToBoxAdapter(
              child: Card(
                color: scheme.errorContainer,
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Text(
                    error!,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.xl, spacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: SectionCard(
              title: l10n.practiceModeLabel,
              icon: Icons.edit_note_outlined,
              children: [
                _ModeCard(
                  icon: Icons.translate_outlined,
                  title: l10n.practiceModeTranslation,
                  subtitle: l10n.practiceModeTranslationDesc,
                  selected: state.gameMode == GameMode.translation,
                  onTap: () => controller.selectMode(GameMode.translation),
                ),
                SizedBox(height: spacing.sm),
                _ModeCard(
                  icon: Icons.quiz_outlined,
                  title: l10n.practiceModeMultipleChoice,
                  subtitle: l10n.practiceModeMultipleChoiceDesc,
                  selected: state.gameMode == GameMode.multipleChoice,
                  onTap: () =>
                      controller.selectMode(GameMode.multipleChoice),
                ),
                SizedBox(height: spacing.sm),
                _ModeCard(
                  icon: Icons.edit_outlined,
                  title: l10n.practiceModeSentenceCheck,
                  subtitle: l10n.practiceModeSentenceCheckDesc,
                  selected: state.gameMode == GameMode.sentenceCheck,
                  onTap: () =>
                      controller.selectMode(GameMode.sentenceCheck),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: SectionCard(
              title: l10n.practiceDifficulty,
              icon: Icons.speed_outlined,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<Difficulty>(
                    segments: [
                      for (final d in Difficulty.values)
                        ButtonSegment(
                          value: d,
                          label: Text(d.name.substring(1)),
                        ),
                    ],
                    selected: {state.difficulty},
                    onSelectionChanged: (value) {
                      controller.selectDifficulty(value.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: SectionCard(
              title: l10n.practiceSentenceLength,
              icon: Icons.short_text_outlined,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<SentenceLength>(
                    segments: [
                      ButtonSegment(
                        value: SentenceLength.short,
                        label: Text(l10n.practiceSentenceLengthShort),
                      ),
                      ButtonSegment(
                        value: SentenceLength.medium,
                        label: Text(l10n.practiceSentenceLengthMedium),
                      ),
                      ButtonSegment(
                        value: SentenceLength.long,
                        label: Text(l10n.practiceSentenceLengthLong),
                      ),
                    ],
                    selected: {state.sentenceLength},
                    onSelectionChanged: (value) {
                      controller.selectSentenceLength(value.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: FilledButton.icon(
              onPressed:
                  llmConfigured ? () => controller.startNewTask() : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.practiceStartButton),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ),
        if (!llmConfigured)
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.practiceNoApiKey,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.xl, spacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: SectionCard(
              title: '',
              icon: Icons.menu_book_outlined,
              children: [
                _LinkTile(
                  icon: Icons.menu_book_outlined,
                  title: l10n.practiceGrammarTitle,
                  subtitle: l10n.practiceGrammarSubtitle,
                  onTap: () => context.push('/practice/grammar'),
                ),
                SizedBox(height: spacing.sm),
                _LinkTile(
                  icon: Icons.history_rounded,
                  title: l10n.practiceHistoryTitle,
                  subtitle: l10n.practiceHistoryEmpty,
                  onTap: () => context.push('/practice/history'),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.64)
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(theme.radii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              SizedBox(width: theme.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(theme.radii.lg),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: scheme.primary),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle:
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.lg),
        ),
      ),
    );
  }
}
