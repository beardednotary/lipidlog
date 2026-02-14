// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LabResultAdapter extends TypeAdapter<LabResult> {
  @override
  final int typeId = 1;

  @override
  LabResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LabResult(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      ldl: fields[2] as double?,
      hdl: fields[3] as double?,
      triglycerides: fields[4] as double?,
      totalCholesterol: fields[5] as double?,
      nonHdl: fields[6] as double?,
      isFasting: fields[7] as bool,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LabResult obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.ldl)
      ..writeByte(3)
      ..write(obj.hdl)
      ..writeByte(4)
      ..write(obj.triglycerides)
      ..writeByte(5)
      ..write(obj.totalCholesterol)
      ..writeByte(6)
      ..write(obj.nonHdl)
      ..writeByte(7)
      ..write(obj.isFasting)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
