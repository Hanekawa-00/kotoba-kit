import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';

part 'history_item.g.dart';

@HiveType(typeId: 10)
class HistoryItem extends HiveObject {
  HistoryItem({
    String? id,
    required this.timestamp,
    required this.gameMode,
    required this.difficulty,
    this.chineseSentence,
    this.userSentence,
    required this.correctedSentence,
    required this.score,
    required this.evaluation,
    required this.explanation,
  }) : id = id ?? const Uuid().v4();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final int timestamp;

  @HiveField(2)
  final String gameMode;

  @HiveField(3)
  final String difficulty;

  @HiveField(4)
  final String? chineseSentence;

  @HiveField(5)
  final String? userSentence;

  @HiveField(6)
  final String correctedSentence;

  @HiveField(7)
  final int score;

  @HiveField(8)
  final String evaluation;

  @HiveField(9)
  final String explanation;
}
