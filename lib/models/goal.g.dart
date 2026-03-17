// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 0;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final templates = (fields[8] as List).cast<String>();
    final totalDays = fields[4] as int;
    final plan = (fields[9] as List).map((e) => (e as List).cast<String>()).toList();
    final constraints = (fields[12] as List).cast<String>();
    final weeklyRestWeekdays = (fields[13] as List).cast<int>();
    return Goal(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      desc: fields[3] as String,
      totalDays: totalDays,
      completedDays: fields[5] as int,
      status: fields[6] as String,
      createdAt: fields[7] as DateTime,
      taskTemplates: templates,
      taskPlan: plan,
      difficulty: fields[10] as String?,
      taskCount: fields[11] as String?,
      constraints: constraints,
      weeklyRestWeekdays: weeklyRestWeekdays,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.desc)
      ..writeByte(4)
      ..write(obj.totalDays)
      ..writeByte(5)
      ..write(obj.completedDays)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.taskTemplates)
      ..writeByte(9)
      ..write(obj.taskPlan)
      ..writeByte(10)
      ..write(obj.difficulty)
      ..writeByte(11)
      ..write(obj.taskCount)
      ..writeByte(12)
      ..write(obj.constraints)
      ..writeByte(13)
      ..write(obj.weeklyRestWeekdays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
