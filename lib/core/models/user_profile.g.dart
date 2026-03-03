// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      age: fields[1] as int?,
      sex: fields[2] as String?,
      focusMode: fields[3] as FocusMode,
      ldlTarget: fields[4] as double?,
      tgTarget: fields[5] as double?,
      onMedication: fields[8] as bool? ?? false,
      habitReminderEnabled: fields[9] as bool? ?? false,
      habitReminderHour: fields[10] as int? ?? 20,
      habitReminderMinute: fields[11] as int? ?? 0,
      medReminderEnabled: fields[12] as bool? ?? false,
      medReminderHour: fields[13] as int? ?? 9,
      medReminderMinute: fields[14] as int? ?? 0,
      labReminderEnabled: fields[15] as bool? ?? false,
      labReminderMonths: fields[16] as int? ?? 3,
      prefersMorningLogging: fields[17] as bool? ?? false,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.sex)
      ..writeByte(3)
      ..write(obj.focusMode)
      ..writeByte(4)
      ..write(obj.ldlTarget)
      ..writeByte(5)
      ..write(obj.tgTarget)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.onMedication)
      ..writeByte(9)
      ..write(obj.habitReminderEnabled)
      ..writeByte(10)
      ..write(obj.habitReminderHour)
      ..writeByte(11)
      ..write(obj.habitReminderMinute)
      ..writeByte(12)
      ..write(obj.medReminderEnabled)
      ..writeByte(13)
      ..write(obj.medReminderHour)
      ..writeByte(14)
      ..write(obj.medReminderMinute)
      ..writeByte(15)
      ..write(obj.labReminderEnabled)
      ..writeByte(16)
      ..write(obj.labReminderMonths)
      ..writeByte(17)
      ..write(obj.prefersMorningLogging);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
