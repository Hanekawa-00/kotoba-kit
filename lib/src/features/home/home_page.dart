import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/section_card.dart';
import '../practice/providers/practice_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = theme.spacing;

    return PageFrame(
      storageId: 'home',
      title: l10n.appTitle,
      subtitle: l10n.homeSubtitle,
      children: [
        _WelcomeBanner(),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 640;
            final cards = [
              _FeatureCard(
                icon: Icons.menu_book_rounded,
                title: l10n.navDictionary,
                subtitle: l10n.dictionarySubtitle,
                color: scheme.primary,
                onTap: () => context.go('/dictionary'),
              ),
              _FeatureCard(
                icon: Icons.edit_note_outlined,
                title: l10n.navPractice,
                subtitle: l10n.practiceSubtitle,
                color: scheme.tertiary,
                onTap: () => context.go('/practice'),
              ),
              _FeatureCard(
                icon: Icons.school_outlined,
                title: l10n.practiceGrammarTitle,
                subtitle: l10n.practiceGrammarSubtitle,
                color: scheme.secondary,
                onTap: () => context.go('/practice/grammar'),
              ),
              _FeatureCard(
                icon: Icons.tune_outlined,
                title: l10n.navSettings,
                subtitle: l10n.settingsSubtitle,
                color: scheme.primaryContainer,
                onTap: () => context.go('/settings'),
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    if (card != cards.last) SizedBox(height: spacing.md),
                  ],
                ],
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: spacing.md,
              mainAxisSpacing: spacing.md,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: cards,
            );
          },
        ),
        _RecentActivity(),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final radii = theme.radii;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(spacing.xl),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radii.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: scheme.primary,
              size: 32,
            ),
          ),
          SizedBox(width: spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: spacing.sm),
                Text(
                  l10n.homeSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final radii = theme.radii;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(radii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.xl),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(radii.md),
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;
    final repository = ref.watch(historyRepositoryProvider);
    final items = repository.loadAll().take(3).toList();

    return SectionCard(
      title: l10n.practiceHistoryTitle,
      icon: Icons.history_rounded,
      children: [
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.md),
            child: Text(
              l10n.practiceHistoryEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...items.map((item) {
            final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
            final dateStr =
                '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            final scoreColor = item.score >= 80
                ? Colors.green
                : item.score >= 60
                    ? Colors.orange
                    : Colors.red;

            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Material(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(theme.radii.lg),
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        child: Text(
                          item.chineseSentence ??
                              item.userSentence ??
                              '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
