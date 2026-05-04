import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../models/practice_types.dart';
import '../providers/practice_providers.dart';

class GrammarBrowseView extends ConsumerWidget {
  const GrammarBrowseView({super.key, required this.state});

  final PracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);
    final grammarRepo = ref.read(grammarRepositoryProvider);

    final filterLevel = state.grammarFilterLevel;
    final points = filterLevel != null
        ? grammarRepo.filterByLevel(state.grammarPoints, filterLevel)
        : state.grammarPoints;

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => controller.goToWelcome(),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    l10n.practiceGrammarTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, 0),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filterLevel == null,
                    onSelected: (_) => controller.setGrammarFilter(null),
                  ),
                  SizedBox(width: spacing.sm),
                  for (final d in Difficulty.values)
                    Padding(
                      padding: EdgeInsets.only(right: spacing.sm),
                      child: FilterChip(
                        label: Text(d.name.toUpperCase()),
                        selected: filterLevel == d,
                        onSelected: (_) => controller.setGrammarFilter(d),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.md),
          Expanded(
            child: points.isEmpty
                ? Center(
                    child: Text(
                      l10n.practiceNoGrammarPoints,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      spacing.lg,
                      0,
                      spacing.lg,
                      spacing.xxl,
                    ),
                    itemCount: points.length,
                    separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      final point = points[index];
                      return _GrammarCard(point: point);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrammarCard extends StatefulWidget {
  const _GrammarCard({required this.point});

  final GrammarPoint point;

  @override
  State<_GrammarCard> createState() => _GrammarCardState();
}

class _GrammarCardState extends State<_GrammarCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = theme.spacing;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(theme.radii.lg),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(theme.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(theme.radii.sm),
                    ),
                    child: Text(
                      widget.point.level.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      widget.point.grammarPoint,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                SizedBox(height: spacing.md),
                _InfoRow(label: '含义', value: widget.point.meaningCn),
                SizedBox(height: spacing.sm),
                _InfoRow(label: '用法', value: widget.point.usage),
                SizedBox(height: spacing.sm),
                _InfoRow(label: '例句', value: widget.point.exampleJa),
                SizedBox(height: 2),
                Text(
                  widget.point.exampleCn,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (widget.point.note.isNotEmpty) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    widget.point.note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.tertiary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
