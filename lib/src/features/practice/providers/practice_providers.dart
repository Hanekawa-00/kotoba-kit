import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/ai/llm_providers.dart';
import '../../../data/repositories/grammar_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../models/history_item.dart';
import '../models/practice_types.dart';
import '../services/practice_ai_service.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  return GrammarRepository();
});

final practiceAiServiceProvider = Provider<PracticeAiService?>((ref) {
  final llm = ref.watch(llmProviderProvider);
  if (llm == null) return null;
  return PracticeAiService(llm: llm);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  try {
    final box = Hive.box<HistoryItem>('practiceHistory');
    return HistoryRepository(box);
  } catch (_) {
    return HistoryRepository.empty();
  }
});

final practiceControllerProvider =
    AsyncNotifierProvider<PracticeController, PracticeState>(
      PracticeController.new,
    );

class PracticeController extends AsyncNotifier<PracticeState> {
  @override
  Future<PracticeState> build() async {
    final grammarRepo = ref.read(grammarRepositoryProvider);
    final grammarPoints = await grammarRepo.loadAll();
    return PracticeState(grammarPoints: grammarPoints);
  }

  PracticeState get _current => state.asData?.value ?? const PracticeState();

  // Mode selection
  void selectMode(GameMode mode) {
    state = AsyncData(_current.copyWith(gameMode: mode));
  }

  void selectDifficulty(Difficulty difficulty) {
    state = AsyncData(_current.copyWith(difficulty: difficulty));
  }

  void selectSentenceLength(SentenceLength length) {
    state = AsyncData(_current.copyWith(sentenceLength: length));
  }

  // Navigation
  void goToWelcome() {
    state = AsyncData(
      _current.copyWith(
        gameState: GameState.welcome,
        currentSentenceTask: null,
        currentMultipleChoiceTask: null,
        feedback: null,
        feedbackExplanation: '',
        userInput: '',
        selectedOptionIndex: null,
        isEvaluating: false,
      ),
    );
  }

  void goToGrammar() {
    state = AsyncData(_current.copyWith(gameState: GameState.grammar));
  }

  void goToHistory() {
    state = AsyncData(_current.copyWith(gameState: GameState.history));
  }

  void setGrammarFilter(Difficulty? level) {
    state = AsyncData(_current.copyWith(grammarFilterLevel: level));
  }

  void updateUserInput(String text) {
    state = AsyncData(_current.copyWith(userInput: text));
  }

  void selectOption(int index) {
    state = AsyncData(_current.copyWith(selectedOptionIndex: index));
  }

  // Task generation
  Future<void> startNewTask() async {
    final current = _current;
    state = AsyncData(
      current.copyWith(
        gameState: GameState.loading,
        errorMessage: null,
        feedback: null,
        feedbackExplanation: '',
        userInput: '',
        selectedOptionIndex: null,
        submitted: false,
        isEvaluating: false,
      ),
    );

    final aiService = ref.read(practiceAiServiceProvider);
    if (aiService == null) {
      state = AsyncData(
        current.copyWith(
          gameState: GameState.welcome,
          errorMessage: 'AI model not configured',
        ),
      );
      return;
    }

    final grammarRepo = ref.read(grammarRepositoryProvider);
    final grammarPoint = grammarRepo.randomByLevel(
      current.grammarPoints,
      current.difficulty,
    );

    try {
      if (current.gameMode == GameMode.multipleChoice) {
        final task = await aiService.generateMultipleChoiceTask(
          difficulty: current.difficulty,
          length: current.sentenceLength,
          grammarPoint: grammarPoint,
        );
        state = AsyncData(
          _current.copyWith(
            gameState: GameState.practicing,
            currentMultipleChoiceTask: task,
            errorMessage: null,
          ),
        );
      } else if (current.gameMode == GameMode.translation) {
        final task = await aiService.generateSentenceTask(
          difficulty: current.difficulty,
          length: current.sentenceLength,
          grammarPoint: grammarPoint,
        );
        state = AsyncData(
          _current.copyWith(
            gameState: GameState.practicing,
            currentSentenceTask: task,
            errorMessage: null,
          ),
        );
      } else {
        // Sentence check mode — no AI generation needed
        state = AsyncData(
          _current.copyWith(
            gameState: GameState.practicing,
            errorMessage: null,
          ),
        );
      }
    } catch (error) {
      state = AsyncData(
        _current.copyWith(
          gameState: GameState.welcome,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> submitTranslation() async {
    final current = _current;
    final task = current.currentSentenceTask;
    if (task == null) return;

    final aiService = ref.read(practiceAiServiceProvider);
    if (aiService == null) return;

    // Stay on practicing while evaluating
    state = AsyncData(current.copyWith(isEvaluating: true));
    final latest = _current;

    try {
      final feedback = await aiService.evaluateTranslation(
        chineseSentence: task.chineseSentence,
        userTranslation: latest.userInput,
        grammarPoint: task.grammarPoint,
        onExplanationChunk: (chunk) {
          final current = _current;
          state = AsyncData(
            current.copyWith(
              feedbackExplanation: current.feedbackExplanation + chunk,
            ),
          );
        },
      );
      state = AsyncData(
        _current.copyWith(
          gameState: GameState.feedback,
          feedback: feedback,
          isEvaluating: false,
        ),
      );

      _saveHistory(
        gameMode: 'translation',
        difficulty: latest.difficulty.name,
        chineseSentence: task.chineseSentence,
        userSentence: latest.userInput,
        feedback: feedback,
      );
    } catch (error) {
      state = AsyncData(
        _current.copyWith(
          gameState: GameState.feedback,
          feedback: PracticeFeedback(
            score: 0,
            evaluation: 'Error',
            correctedSentence: '',
            explanation: 'Failed to get feedback: $error',
          ),
          isEvaluating: false,
        ),
      );
    }
  }

  Future<void> submitSentenceCheck() async {
    final current = _current;
    final aiService = ref.read(practiceAiServiceProvider);
    if (aiService == null) return;

    // Stay on practicing while evaluating
    state = AsyncData(current.copyWith(isEvaluating: true));
    final latest = _current;

    try {
      final feedback = await aiService.evaluateJapaneseSentence(
        userSentence: latest.userInput,
        onExplanationChunk: (chunk) {
          final current = _current;
          state = AsyncData(
            current.copyWith(
              feedbackExplanation: current.feedbackExplanation + chunk,
            ),
          );
        },
      );
      state = AsyncData(
        _current.copyWith(
          gameState: GameState.feedback,
          feedback: feedback,
          isEvaluating: false,
        ),
      );

      _saveHistory(
        gameMode: 'sentenceCheck',
        difficulty: latest.difficulty.name,
        userSentence: latest.userInput,
        feedback: feedback,
      );
    } catch (error) {
      state = AsyncData(
        _current.copyWith(
          gameState: GameState.feedback,
          feedback: PracticeFeedback(
            score: 0,
            evaluation: 'Error',
            correctedSentence: '',
            explanation: 'Failed to get feedback: $error',
          ),
          isEvaluating: false,
        ),
      );
    }
  }

  Future<void> submitChoice() async {
    final current = _current;
    final task = current.currentMultipleChoiceTask;
    if (task == null) return;

    // If already submitted, go to feedback view
    if (current.submitted) {
      final isCorrect = current.selectedOptionIndex == task.correctOptionIndex;
      final selectedIndex = current.selectedOptionIndex;
      final score = selectedIndex != null ? (isCorrect ? 100 : 0) : 0;
      final evaluation = selectedIndex != null
          ? (isCorrect ? '正确！' : '不正确')
          : '跳过';

      state = AsyncData(
        current.copyWith(
          gameState: GameState.feedback,
          feedback: PracticeFeedback(
            score: score,
            evaluation: evaluation,
            correctedSentence: isCorrect
                ? ''
                : task.options[task.correctOptionIndex],
            explanation: task.explanation,
          ),
        ),
      );

      _saveHistory(
        gameMode: 'multipleChoice',
        difficulty: current.difficulty.name,
        chineseSentence: task.chineseSentence,
        userSentence: selectedIndex != null
            ? task.options[selectedIndex]
            : null,
        feedback: PracticeFeedback(
          score: score,
          evaluation: evaluation,
          correctedSentence: isCorrect
              ? ''
              : task.options[task.correctOptionIndex],
          explanation: task.explanation,
        ),
      );
      return;
    }

    // First submission: just reveal the answer
    state = AsyncData(current.copyWith(submitted: true));
  }

  void _saveHistory({
    required String gameMode,
    required String difficulty,
    String? chineseSentence,
    String? userSentence,
    required PracticeFeedback feedback,
  }) {
    final repo = ref.read(historyRepositoryProvider);
    repo.addItem(
      HistoryItem(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        gameMode: gameMode,
        difficulty: difficulty,
        chineseSentence: chineseSentence,
        userSentence: userSentence,
        correctedSentence: feedback.correctedSentence,
        score: feedback.score,
        evaluation: feedback.evaluation,
        explanation: feedback.explanation,
      ),
    );
  }
}

class PracticeState {
  const PracticeState({
    this.gameState = GameState.welcome,
    this.gameMode = GameMode.translation,
    this.difficulty = Difficulty.n4,
    this.sentenceLength = SentenceLength.medium,
    this.currentSentenceTask,
    this.currentMultipleChoiceTask,
    this.userInput = '',
    this.selectedOptionIndex,
    this.isEvaluating = false,
    this.submitted = false,
    this.feedback,
    this.feedbackExplanation = '',
    this.grammarPoints = const [],
    this.grammarFilterLevel,
    this.historyItems = const [],
    this.errorMessage,
  });

  final GameState gameState;
  final GameMode gameMode;
  final Difficulty difficulty;
  final SentenceLength sentenceLength;
  final SentenceTask? currentSentenceTask;
  final MultipleChoiceTask? currentMultipleChoiceTask;
  final String userInput;
  final int? selectedOptionIndex;
  final bool isEvaluating;
  final bool submitted;
  final PracticeFeedback? feedback;
  final String feedbackExplanation;
  final List<GrammarPoint> grammarPoints;
  final Difficulty? grammarFilterLevel;
  final List<dynamic> historyItems;
  final String? errorMessage;

  PracticeState copyWith({
    GameState? gameState,
    GameMode? gameMode,
    Difficulty? difficulty,
    SentenceLength? sentenceLength,
    SentenceTask? currentSentenceTask,
    MultipleChoiceTask? currentMultipleChoiceTask,
    String? userInput,
    int? selectedOptionIndex,
    bool? isEvaluating,
    bool? submitted,
    PracticeFeedback? feedback,
    String? feedbackExplanation,
    List<GrammarPoint>? grammarPoints,
    Difficulty? grammarFilterLevel,
    List<dynamic>? historyItems,
    String? errorMessage,
  }) {
    return PracticeState(
      gameState: gameState ?? this.gameState,
      gameMode: gameMode ?? this.gameMode,
      difficulty: difficulty ?? this.difficulty,
      sentenceLength: sentenceLength ?? this.sentenceLength,
      currentSentenceTask: currentSentenceTask ?? this.currentSentenceTask,
      currentMultipleChoiceTask:
          currentMultipleChoiceTask ?? this.currentMultipleChoiceTask,
      userInput: userInput ?? this.userInput,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      submitted: submitted ?? this.submitted,
      feedback: feedback ?? this.feedback,
      feedbackExplanation: feedbackExplanation ?? this.feedbackExplanation,
      grammarPoints: grammarPoints ?? this.grammarPoints,
      grammarFilterLevel: grammarFilterLevel ?? this.grammarFilterLevel,
      historyItems: historyItems ?? this.historyItems,
      errorMessage: errorMessage,
    );
  }
}
