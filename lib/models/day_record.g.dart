// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_record.dart';

class DayRecordAdapter extends TypeAdapter<DayRecord> {
  @override
  final int typeId = 1;

  @override
  DayRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayRecord(
      id: fields[0] as String,
      goalId: fields[1] as String,
      date: fields[2] as DateTime,
      dayNumber: fields[3] as int,
      tasks: (fields[4] as List).cast<TaskRecord>(),
      isDeferred: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DayRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.dayNumber)
      ..writeByte(4)
      ..write(obj.tasks)
      ..writeByte(5)
      ..write(obj.isDeferred);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskRecordAdapter extends TypeAdapter<TaskRecord> {
  @override
  final int typeId = 2;

  @override
  TaskRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskRecord(
      taskText: fields[0] as String,
      isDone: fields[1] as bool,
      doneAt: fields[2] as DateTime?,
      isMakeup: fields[3] as bool,
      isDeferred: fields[4] as bool,
      deferredTo: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.taskText)
      ..writeByte(1)
      ..write(obj.isDone)
      ..writeByte(2)
      ..write(obj.doneAt)
      ..writeByte(3)
      ..write(obj.isMakeup)
      ..writeByte(4)
      ..write(obj.isDeferred)
      ..writeByte(5)
      ..write(obj.deferredTo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
