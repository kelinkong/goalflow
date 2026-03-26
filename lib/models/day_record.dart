class DayRecord {
  late String id; // "${goalId}_${dateStr}"  e.g. "abc_2025-06-12"
  late String goalId;
  late DateTime date;
  late int dayNumber; // 1-based day in the goal
  late List<TaskRecord> tasks;
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

class TaskRecord {
  late String taskText;
  late bool isDone;
  late DateTime? doneAt;
  late bool isMakeup; // retroactive checkin
  late bool isDeferred; // this specific task deferred
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
