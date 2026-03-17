import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/day_record.dart';
import '../services/hive_service.dart';

class AppState extends ChangeNotifier {
  final HiveService _hive = HiveService();

  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  void loadGoals() {
    _goals = _hive.getGoals();
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    await _hive.saveGoal(goal);
    loadGoals();
  }

  Future<void> updateGoalStatus(String id, String status) async {
    final goal = _hive.getGoal(id);
    if (goal == null) return;
    goal.status = status;
    await _hive.saveGoal(goal);
    loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _hive.deleteGoal(id);
    loadGoals();
  }

  // ── Day Records ──────────────────────────────────────────────────

  Future<DayRecord> getOrCreateRecord(Goal goal, DateTime date) async {
    return await _hive.getOrCreateRecord(goal, date);
  }

  DayRecord? getRecord(String goalId, DateTime date) =>
      _hive.getRecord(goalId, date);

  List<DayRecord> getRecordsForGoal(String goalId) =>
      _hive.getRecordsForGoal(goalId);

  double getGoalProgress(Goal goal) => _hive.getGoalProgress(goal);

  int getGoalProgressPercent(Goal goal) => _hive.getGoalProgressPercent(goal);

  int getGoalTotalTasks(Goal goal) => _hive.getGoalTotalTasks(goal);

  int getGoalDoneTasks(Goal goal) => _hive.getGoalDoneTasks(goal);

  Future<void> checkIn(Goal goal, DateTime date, int taskIdx, {bool isMakeup = false}) async {
    await _hive.checkInTask(goal, date, taskIdx, isMakeup: isMakeup);
    loadGoals();
    notifyListeners();
  }

  Future<void> uncheck(Goal goal, DateTime date, int taskIdx) async {
    await _hive.uncheckTask(goal, date, taskIdx);
    loadGoals();
    notifyListeners();
  }

  Future<void> deferTask(Goal goal, DateTime date, int taskIdx) async {
    await _hive.deferTask(goal, date, taskIdx);
    notifyListeners();
  }
}
