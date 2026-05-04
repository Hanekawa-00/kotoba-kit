import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/app_state_views.dart';
import 'models/practice_types.dart';
import 'providers/practice_providers.dart';
import 'widgets/feedback_view.dart';
import 'widgets/multiple_choice_exercise.dart';
import 'widgets/sentence_check_exercise.dart';
import 'widgets/translation_exercise.dart';
import 'widgets/welcome_view.dart';

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(practiceControllerProvider);

    return asyncState.when(
      data: (state) => _buildForState(state),
      loading: () => const SafeArea(
        top: false,
        bottom: false,
        child: Center(child: AppLoadingView()),
      ),
      error: (error, _) => SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: AppErrorView(message: error.toString()),
        ),
      ),
    );
  }

  Widget _buildForState(PracticeState state) {
    return switch (state.gameState) {
      GameState.welcome => PracticeWelcomeView(state: state),
      GameState.loading => _LoadingView(),
      GameState.practicing => switch (state.gameMode) {
          GameMode.translation => TranslationExercise(state: state),
          GameMode.multipleChoice => MultipleChoiceExercise(state: state),
          GameMode.sentenceCheck => SentenceCheckExercise(state: state),
        },
      GameState.feedback => FeedbackView(state: state),
      _ => PracticeWelcomeView(state: state),
    };
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingView(),
            SizedBox(height: Theme.of(context).spacing.md),
            Text(l10n.practiceGenerating),
          ],
        ),
      ),
    );
  }
}

