import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../models/history_item.dart';
import '../providers/practice_providers.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key, required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);
    final repository = ref.read(historyRepositoryProvider);
    final items = repository.loadAll();

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
                    l10n.practiceHistoryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      l10n.practiceHistoryEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      spacing.lg,
                      spacing.md,
                      spacing.lg,
                      spacing.xxl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _HistoryCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({required this.item});

  final HistoryItem item;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = theme.spacing;
    final item = widget.item;

    final scoreColor = item.score >= 80
        ? Colors.green
        : item.score >= 60
        ? Colors.orange
        : Colors.red;

    final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withValues(alpha: 0.18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.score}',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.chineseSentence ?? item.userSentence ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${item.gameMode} · ${item.difficulty} · $dateStr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
                if (item.evaluation.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm),
                    child: Text(
                      item.evaluation,
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (item.correctedSentence.isNotEmpty) ...[
                  Text(
                    '修正:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(item.correctedSentence),
                  SizedBox(height: spacing.sm),
                ],
                if (item.explanation.isNotEmpty) ...[
                  Text(
                    '解释:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(item.explanation),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
