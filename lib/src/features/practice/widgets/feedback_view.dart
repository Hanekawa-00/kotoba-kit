import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../providers/practice_providers.dart';

class FeedbackView extends ConsumerWidget {
  const FeedbackView({super.key, required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);
    final feedback = state.feedback;
    final isEvaluating = state.isEvaluating;
    final streamingText = state.feedbackExplanation;

    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // Back button row
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.sm,
                  spacing.sm,
                  spacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => controller.goToWelcome(),
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        l10n.practiceFeedbackTitle,
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    spacing.lg,
                    0,
                    spacing.lg,
                    spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (feedback != null) ...[
                        // Score
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _scoreColor(
                                    feedback.score,
                                  ).withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: _scoreColor(feedback.score),
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${feedback.score}',
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                          color: _scoreColor(feedback.score),
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing.sm),
                              Text(
                                feedback.evaluation,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _scoreColor(feedback.score),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing.xl),
                        // Corrected sentence
                        if (feedback.correctedSentence.isNotEmpty) ...[
                          Text(
                            l10n.practiceCorrectedSentence,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: spacing.sm),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(spacing.md),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(
                                theme.radii.md,
                              ),
                            ),
                            child: Text(
                              feedback.correctedSentence,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.xl),
                        ],
                        // Explanation
                        Text(
                          l10n.practiceExplanation,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        MarkdownBody(
                          data: feedback.explanation.isNotEmpty
                              ? feedback.explanation
                              : 'No detailed explanation available.',
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            theme,
                          ).copyWith(p: theme.textTheme.bodyMedium),
                        ),
                      ] else if (isEvaluating) ...[
                        // Streaming progress
                        SizedBox(height: spacing.xl),
                        const LinearProgressIndicator(),
                        SizedBox(height: spacing.lg),
                        if (streamingText.isNotEmpty)
                          MarkdownBody(
                            data: streamingText,
                            styleSheet: MarkdownStyleSheet.fromTheme(
                              theme,
                            ).copyWith(p: theme.textTheme.bodyMedium),
                          )
                        else
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: spacing.xxl,
                              ),
                              child: Text(
                                l10n.practiceEvaluating,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions (only when feedback is complete)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.lg,
                  spacing.md,
                  spacing.lg,
                  spacing.xl + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isEvaluating
                            ? null
                            : () => controller.goToWelcome(),
                        child: Text(l10n.practiceBackToMenu),
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: isEvaluating
                            ? null
                            : () => controller.startNewTask(),
                        child: Text(l10n.practiceNextTask),
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

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
