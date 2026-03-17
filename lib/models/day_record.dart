import 'package:hive/hive.dart';

part 'day_record.g.dart';

@HiveType(typeId: 1)
class DayRecord extends HiveObject {
  @HiveField(0)
  late String id; // "${goalId}_${dateStr}"  e.g. "abc_2025-06-12"

  @HiveField(1)
  late String goalId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late int dayNumber; // 1-based day in the goal

  @HiveField(4)
  late List<TaskRecord> tasks;

  @HiveField(5)
  late bool isDeferred; // whole day deferred to next

  DayRecord({
    required this.id,
    required this.goalId,
    required this.date,
    required this.dayNumber,
    required this.tasks,
    this.isDeferred = false,
  });

  bool get allDone => tasks.isNotEmpty && tasks.every((t) => t.isDone);
  bool get anyDone => tasks.any((t) => t.isDone);
  int get doneCount => tasks.where((t) => t.isDone).length;

  static String makeId(String goalId, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${goalId}_${d.toIso8601String().substring(0, 10)}';
  }
}

@HiveType(typeId: 2)
class TaskRecord extends HiveObject {
  @HiveField(0)
  late String taskText;

  @HiveField(1)
  late bool isDone;

  @HiveField(2)
  late DateTime? doneAt;

  @HiveField(3)
  late bool isMakeup; // retroactive checkin

  @HiveField(4)
  late bool isDeferred; // this specific task deferred

  @HiveField(5)
  late DateTime? deferredTo; // deferred to this date

  TaskRecord({
    required this.taskText,
    this.isDone = false,
    this.doneAt,
    this.isMakeup = false,
    this.isDeferred = false,
    this.deferredTo,
  });
}
