import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../providers/practice_providers.dart';

class TranslationExercise extends ConsumerStatefulWidget {
  const TranslationExercise({super.key, required this.state});

  final dynamic state;

  @override
  ConsumerState<TranslationExercise> createState() =>
      _TranslationExerciseState();
}

class _TranslationExerciseState extends ConsumerState<TranslationExercise> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.userInput);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final scheme = theme.colorScheme;
    final controller = ref.read(practiceControllerProvider.notifier);
    final state = widget.state;

    final task = state.currentSentenceTask;
    final grammarPoint = task?.grammarPoint;

    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
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
                                l10n.practiceModeTranslation,
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
                        Text(
                          l10n.practiceChineseOriginal,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
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
                            task?.chineseSentence ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
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
                              borderRadius: BorderRadius.circular(
                                theme.radii.md,
                              ),
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
                        Text(
                          l10n.practiceYourTranslation,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 5,
                          minLines: 3,
                          enabled: !state.isEvaluating,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: l10n.practiceJapaneseInputHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                theme.radii.md,
                              ),
                            ),
                          ),
                          onChanged: controller.updateUserInput,
                        ),
                      ],
                    ),
                  ),
                ),
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
                      onPressed:
                          _controller.text.trim().isNotEmpty &&
                              !state.isEvaluating
                          ? () {
                              _focusNode.unfocus();
                              controller.submitTranslation();
                            }
                          : null,
                      icon: state.isEvaluating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        state.isEvaluating
                            ? l10n.practiceEvaluating
                            : l10n.practiceSubmit,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
