import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../providers/practice_providers.dart';

class SentenceCheckExercise extends ConsumerStatefulWidget {
  const SentenceCheckExercise({super.key, required this.state});

  final dynamic state;

  @override
  ConsumerState<SentenceCheckExercise> createState() =>
      _SentenceCheckExerciseState();
}

class _SentenceCheckExerciseState extends ConsumerState<SentenceCheckExercise> {
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
                      spacing.lg, spacing.lg, spacing.lg, spacing.md,
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
                                l10n.practiceModeSentenceCheck,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.md),
                        Text(
                          l10n.practiceSentenceCheckInstruction,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: spacing.xl),
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 8,
                          minLines: 5,
                          enabled: !state.isEvaluating,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: l10n.practiceSentenceCheckInputHint,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(theme.radii.md),
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
                      onPressed: _controller.text.trim().isNotEmpty &&
                              !state.isEvaluating
                          ? () {
                              _focusNode.unfocus();
                              controller.submitSentenceCheck();
                            }
                          : null,
                      icon: state.isEvaluating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
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
