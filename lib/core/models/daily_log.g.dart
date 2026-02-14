// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogAdapter extends TypeAdapter<DailyLog> {
  @override
  final int typeId = 2;

  @override
  DailyLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      alcoholLevel: fields[2] as AlcoholLevel,
      stepsGoalHit: fields[3] as bool,
      lateNightEating: fields[4] as bool,
      highCarbDay: fields[5] as bool,
      highSatFatDay: fields[6] as bool,
      sleepCategory: fields[7] as SleepCategory,
      medicationTaken: fields[8] as bool,
      stressLevel: fields[9] as StressLevel,
      notes: fields[10] as String?,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLog obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.alcoholLevel)
      ..writeByte(3)
      ..write(obj.stepsGoalHit)
      ..writeByte(4)
      ..write(obj.lateNightEating)
      ..writeByte(5)
      ..write(obj.highCarbDay)
      ..writeByte(6)
      ..write(obj.highSatFatDay)
      ..writeByte(7)
      ..write(obj.sleepCategory)
      ..writeByte(8)
      ..write(obj.medicationTaken)
      ..writeByte(9)
      ..write(obj.stressLevel)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
