// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreSnapshotAdapter extends TypeAdapter<ScoreSnapshot> {
  @override
  final int typeId = 3;

  @override
  ScoreSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreSnapshot(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      overallScore: fields[2] as double,
      labScore: fields[3] as double,
      behaviorScore: fields[4] as double,
      trendScore: fields[5] as double,
      goalScore: fields[6] as double?,
      deltaToGoal: fields[7] as double?,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreSnapshot obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.overallScore)
      ..writeByte(3)
      ..write(obj.labScore)
      ..writeByte(4)
      ..write(obj.behaviorScore)
      ..writeByte(5)
      ..write(obj.trendScore)
      ..writeByte(6)
      ..write(obj.goalScore)
      ..writeByte(7)
      ..write(obj.deltaToGoal)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
