import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';
import '../models/day_record.dart';

class HiveService {
  static const _goalsBox = 'goals';
  static const _recordsBox = 'day_records';
  static const _resetLocalDataOnStartup = true; // dev-only: clear old schema data

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(DayRecordAdapter());
    Hive.registerAdapter(TaskRecordAdapter());
    if (_resetLocalDataOnStartup) {
      await Hive.deleteBoxFromDisk(_goalsBox);
      await Hive.deleteBoxFromDisk(_recordsBox);
    }
    await Hive.openBox<Goal>(_goalsBox);
    await Hive.openBox<DayRecord>(_recordsBox);
  }

  // ── Goals ──────────────────────────────────────────────────────
  Box<Goal> get _goals => Hive.box<Goal>(_goalsBox);
  Box<DayRecord> get _records => Hive.box<DayRecord>(_recordsBox);

  List<Goal> getGoals() => _goals.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Goal? getGoal(String id) =>
      _goals.values.where((g) => g.id == id).firstOrNull;

  Future<void> saveGoal(Goal goal) async {
    await _goals.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    await _goals.delete(id);
    // Also delete all records for this goal
    final keys = _records.values
        .where((r) => r.goalId == id)
        .map((r) => r.key)
        .toList();
    await _records.deleteAll(keys);
  }

  // ── DayRecords ─────────────────────────────────────────────────

  DayRecord? getRecord(String goalId, DateTime date) {
    final id = DayRecord.makeId(goalId, date);
    return _records.get(id);
  }

  List<DayRecord> getRecordsForGoal(String goalId) =>
      _records.values.where((r) => r.goalId == goalId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Get or create today's record for a goal.
  /// If today's record doesn't exist, tries to pull deferred tasks from yesterday.
  Future<DayRecord> getOrCreateRecord(Goal goal, DateTime date) async {
    final id = DayRecord.makeId(goal.id, date);
    if (_records.containsKey(id)) return _records.get(id)!;

    // Build task list: start from plan for the day, then add any deferred tasks from yesterday
    final dayNum = goal.dayNumberForDate(date);
    final yesterday = date.subtract(const Duration(days: 1));
    final yesterdayRecord = getRecord(goal.id, yesterday);

    final tasksForDay = dayNum != null ? goal.tasksForDayNumber(dayNum) : const <String>[];
    final tasks = tasksForDay.map((text) => TaskRecord(taskText: text)).toList();

    // Inject deferred tasks from yesterday
    if (yesterdayRecord != null) {
      for (final t in yesterdayRecord.tasks) {
        if (t.isDeferred && t.deferredTo != null) {
          final target = DateTime(t.deferredTo!.year, t.deferredTo!.month, t.deferredTo!.day);
          final d = DateTime(date.year, date.month, date.day);
          if (target == d) {
            // Find matching task and mark it as from-deferred
            final idx = tasks.indexWhere((x) => x.taskText == t.taskText);
            if (idx >= 0) {
              tasks[idx] = TaskRecord(taskText: t.taskText); // reset, will appear in today
            } else {
              tasks.add(TaskRecord(taskText: t.taskText));
            }
          }
        }
      }
    }

    final d = DateTime(date.year, date.month, date.day);

    final record = DayRecord(
      id: id,
      goalId: goal.id,
      date: d,
      dayNumber: dayNum ?? 0,
      tasks: tasks,
    );
    await _records.put(id, record);
    return record;
  }

  Future<void> saveRecord(DayRecord record) async {
    await _records.put(record.id, record);
  }

  /// Check in a task (mark done)
  Future<void> checkInTask(Goal goal, DateTime date, int taskIndex, {bool isMakeup = false}) async {
    final record = await getOrCreateRecord(goal, date);
    if (taskIndex >= record.tasks.length) return;
    record.tasks[taskIndex].isDone = true;
    record.tasks[taskIndex].doneAt = DateTime.now();
    record.tasks[taskIndex].isMakeup = isMakeup;
    await saveRecord(record);

    // Always recompute completed days to keep progress in sync
    goal.completedDays = _countCompletedDays(goal);
    await saveGoal(goal);
  }

  /// Defer a task to the next day
  Future<void> deferTask(Goal goal, DateTime date, int taskIndex) async {
    final record = await getOrCreateRecord(goal, date);
    if (taskIndex >= record.tasks.length) return;
    final nextDay = date.add(const Duration(days: 1));
    record.tasks[taskIndex].isDeferred = true;
    record.tasks[taskIndex].deferredTo = nextDay;
    await saveRecord(record);

    // Ensure tomorrow's record is created with this deferred task
    await getOrCreateRecord(goal, nextDay);
  }

  int _countCompletedDays(Goal goal) {
    return _records.values
        .where((r) => r.goalId == goal.id && r.allDone)
        .length;
  }

  int getGoalTotalTasks(Goal goal) {
    if (goal.taskPlan.isNotEmpty) {
      return goal.taskPlan.fold<int>(0, (a, b) => a + b.length);
    }
    return goal.taskTemplates.length * goal.totalDays;
  }

  int getGoalDoneTasks(Goal goal) {
    return _records.values
        .where((r) => r.goalId == goal.id)
        .fold<int>(0, (a, r) => a + r.doneCount);
  }

  double getGoalProgress(Goal goal) {
    final total = getGoalTotalTasks(goal);
    if (total == 0) return 0;
    final done = getGoalDoneTasks(goal);
    return done / total;
  }

  int getGoalProgressPercent(Goal goal) {
    return (getGoalProgress(goal) * 100).round();
  }

  /// Undo a check-in
  Future<void> uncheckTask(Goal goal, DateTime date, int taskIndex) async {
    final record = getRecord(goal.id, date);
    if (record == null || taskIndex >= record.tasks.length) return;
    record.tasks[taskIndex].isDone = false;
    record.tasks[taskIndex].doneAt = null;
    record.tasks[taskIndex].isMakeup = false;
    await saveRecord(record);
    goal.completedDays = _countCompletedDays(goal);
    await saveGoal(goal);
  }
}
