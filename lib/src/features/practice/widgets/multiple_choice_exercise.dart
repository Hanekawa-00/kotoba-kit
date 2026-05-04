import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../providers/practice_providers.dart';

class MultipleChoiceExercise extends ConsumerWidget {
  const MultipleChoiceExercise({super.key, required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);

    final task = state.currentMultipleChoiceTask;
    final selected = state.selectedOptionIndex;
    final submitted = state.submitted;
    final grammarPoint = task?.grammarPoint;

    if (task == null) {
      return const SafeArea(
        top: false,
        bottom: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    spacing.lg,
                    spacing.lg,
                    spacing.lg,
                    spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => controller.goToWelcome(),
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Text(
                              l10n.practiceModeMultipleChoice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.lg),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(spacing.lg),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(
                            alpha: 0.32,
                          ),
                          borderRadius: BorderRadius.circular(theme.radii.lg),
                          border: Border.all(color: scheme.primaryContainer),
                        ),
                        child: Text(
                          task.chineseSentence,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (grammarPoint != null) ...[
                        SizedBox(height: spacing.md),
                        Container(
                          padding: EdgeInsets.all(spacing.md),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(theme.radii.md),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: scheme.onTertiaryContainer,
                                size: 18,
                              ),
                              SizedBox(width: spacing.sm),
                              Expanded(
                                child: Text(
                                  '${grammarPoint.grammarPoint}: ${grammarPoint.meaningCn}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: spacing.xl),
                      ...List.generate(task.options.length, (index) {
                        final option = task.options[index];
                        final isSelected = selected == index;
                        Color? bgColor;
                        if (submitted) {
                          if (index == task.correctOptionIndex) {
                            bgColor = Colors.green.withValues(alpha: 0.18);
                          } else if (isSelected) {
                            bgColor = Colors.red.withValues(alpha: 0.18);
                          }
                        } else if (isSelected) {
                          bgColor = scheme.primaryContainer.withValues(
                            alpha: 0.42,
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: spacing.sm),
                          child: Material(
                            color: bgColor ?? scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(theme.radii.lg),
                            child: InkWell(
                              onTap: selected == null && !submitted
                                  ? () => controller.selectOption(index)
                                  : null,
                              borderRadius: BorderRadius.circular(
                                theme.radii.lg,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(spacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? scheme.primary
                                            : scheme.surfaceContainerHighest,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? scheme.onPrimary
                                              : scheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing.md),
                                    Expanded(
                                      child: Text(
                                        option,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              if (!submitted)
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
                          onPressed: () => controller.submitChoice(),
                          child: Text(l10n.practiceNotSure),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: selected != null
                              ? () => controller.submitChoice()
                              : null,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(l10n.practiceSubmit),
                        ),
                      ),
                    ],
                  ),
                ),
              if (submitted)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.lg,
                    spacing.md,
                    spacing.lg,
                    spacing.xl + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => controller.submitChoice(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.practiceMultipleChoiceViewExplanation),
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
