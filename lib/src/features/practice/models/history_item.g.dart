// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryItemAdapter extends TypeAdapter<HistoryItem> {
  @override
  final typeId = 10;

  @override
  HistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryItem(
      id: fields[0] as String?,
      timestamp: (fields[1] as num).toInt(),
      gameMode: fields[2] as String,
      difficulty: fields[3] as String,
      chineseSentence: fields[4] as String?,
      userSentence: fields[5] as String?,
      correctedSentence: fields[6] as String,
      score: (fields[7] as num).toInt(),
      evaluation: fields[8] as String,
      explanation: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.gameMode)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.chineseSentence)
      ..writeByte(5)
      ..write(obj.userSentence)
      ..writeByte(6)
      ..write(obj.correctedSentence)
      ..writeByte(7)
      ..write(obj.score)
      ..writeByte(8)
      ..write(obj.evaluation)
      ..writeByte(9)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
