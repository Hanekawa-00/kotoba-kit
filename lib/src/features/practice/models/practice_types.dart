import 'package:flutter/foundation.dart';

enum Difficulty { n5, n4, n3, n2, n1 }

enum SentenceLength { short, medium, long }

enum GameMode { translation, multipleChoice, sentenceCheck }

enum GameState { welcome, loading, practicing, feedback, grammar, history }

@immutable
class GrammarPoint {
  const GrammarPoint({
    required this.level,
    required this.grammarPoint,
    required this.meaningCn,
    required this.usage,
    required this.exampleJa,
    required this.exampleCn,
    required this.note,
  });

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      level: _parseLevel(json['level'] as String?),
      grammarPoint: json['grammar_point'] as String? ?? '',
      meaningCn: json['meaning_cn'] as String? ?? '',
      usage: json['usage'] as String? ?? '',
      exampleJa: json['example_ja'] as String? ?? '',
      exampleCn: json['example_cn'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  static Difficulty _parseLevel(String? level) {
    return switch (level) {
      'N5' => Difficulty.n5,
      'N4' => Difficulty.n4,
      'N3' => Difficulty.n3,
      'N2' => Difficulty.n2,
      'N1' => Difficulty.n1,
      _ => Difficulty.n1,
    };
  }

  final Difficulty level;
  final String grammarPoint;
  final String meaningCn;
  final String usage;
  final String exampleJa;
  final String exampleCn;
  final String note;
}

@immutable
class SentenceTask {
  const SentenceTask({required this.chineseSentence, this.grammarPoint});

  final String chineseSentence;
  final GrammarPoint? grammarPoint;
}

@immutable
class MultipleChoiceTask {
  const MultipleChoiceTask({
    required this.chineseSentence,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.grammarPoint,
  });

  final String chineseSentence;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final GrammarPoint? grammarPoint;
}

@immutable
class PracticeFeedback {
  const PracticeFeedback({
    required this.score,
    required this.evaluation,
    required this.correctedSentence,
    required this.explanation,
  });

  final int score;
  final String evaluation;
  final String correctedSentence;
  final String explanation;
}
