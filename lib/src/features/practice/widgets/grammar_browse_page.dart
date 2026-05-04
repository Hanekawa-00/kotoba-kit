import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../shared/widgets/page_frame.dart';
import '../models/practice_types.dart';
import '../providers/practice_providers.dart';

class GrammarBrowsePage extends ConsumerStatefulWidget {
  const GrammarBrowsePage({super.key});

  @override
  ConsumerState<GrammarBrowsePage> createState() => _GrammarBrowsePageState();
}

class _GrammarBrowsePageState extends ConsumerState<GrammarBrowsePage> {
  Difficulty? _filterLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final grammarRepo = ref.read(grammarRepositoryProvider);
    final asyncPoints = ref.watch(_grammarPointsProvider);

    final allPoints = asyncPoints.asData?.value ?? [];
    final points = _filterLevel != null
        ? grammarRepo.filterByLevel(allPoints, _filterLevel!)
        : allPoints;

    return PageFrame(
      storageId: 'practice-grammar',
      title: l10n.practiceGrammarTitle,
      subtitle: l10n.practiceGrammarSubtitle,
      trailing: OutlinedButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          context.go('/practice');
        },
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l10n.practiceBackToMenu),
      ),
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterLevel == null,
                onSelected: (_) => setState(() => _filterLevel = null),
              ),
              SizedBox(width: spacing.sm),
              for (final d in Difficulty.values)
                Padding(
                  padding: EdgeInsets.only(right: spacing.sm),
                  child: FilterChip(
                    label: Text(d.name.toUpperCase()),
                    selected: _filterLevel == d,
                    onSelected: (_) => setState(() => _filterLevel = d),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: spacing.md),
        if (points.isEmpty)
          Center(
            child: Text(
              l10n.practiceNoGrammarPoints,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...points.map((point) => _GrammarCard(point: point)),
      ],
    );
  }
}

final _grammarPointsProvider = FutureProvider<List<GrammarPoint>>((ref) {
  return ref.read(grammarRepositoryProvider).loadAll();
});

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

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Material(
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
