import 'dart:convert';
import 'dart:async';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/goal.dart';
import '../models/goal_decomposition.dart';
import '../models/goal_template.dart';
import '../models/medal_item.dart';
import '../models/ranking_entry.dart';
import '../models/daily_review.dart';
import '../services/api_service.dart';
import '../widgets/share_card.dart';

class TaskViewItem {
  final String key;
  final String text;
  final bool done;
  final bool deferred;
  final bool isMakeup;

  const TaskViewItem({
    required this.key,
    required this.text,
    required this.done,
    required this.deferred,
    this.isMakeup = false,
  });

  TaskViewItem copyWith({
    String? key,
    String? text,
    bool? done,
    bool? deferred,
    bool? isMakeup,
  }) {
    return TaskViewItem(
      key: key ?? this.key,
      text: text ?? this.text,
      done: done ?? this.done,
      deferred: deferred ?? this.deferred,
      isMakeup: isMakeup ?? this.isMakeup,
    );
  }
}

class TimelineDayView {
  final DateTime date;
  final int dayNumber;
  final List<TaskViewItem> tasks;

  const TimelineDayView({
    required this.date,
    required this.dayNumber,
    required this.tasks,
  });
}

class _ParsedTaskKey {
  final String goalId;
  final DateTime sourceDate;
  final int taskIndex;

  const _ParsedTaskKey({
    required this.goalId,
    required this.sourceDate,
    required this.taskIndex,
  });
}

class TaskActionResult {
  final bool goalCompleted;

  const TaskActionResult({
    this.goalCompleted = false,
  });
}

class AppState extends ChangeNotifier {
  static const _tokenStorageKey = 'auth_token';
  static const _dailyAiDecomposeLimit = 10;
  static const _aiDecomposeCountKeyPrefix = 'ai_decompose_count';
  final ApiService _api = ApiService();
  String? _globalMessage;

  List<Goal> _goals = [];
  List<Goal> get goals => _goals;
  String? get globalMessage => _globalMessage;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _userId;
  String? _userEmail;
  String? _userNickname;
  String? _userAvatar;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userNickname => _userNickname;
  String? get userAvatar => _userAvatar;

  final Map<String, List<TimelineDayView>> _timelineByGoal = {};
  final Map<String, Map<String, List<TaskViewItem>>> _taskViewsByGoalDate = {};
  final Set<String> _pendingActions = <String>{};
  List<GoalTemplate> _publicTemplates = [];
  List<GoalTemplate> get publicTemplates => _publicTemplates;
  List<GoalTemplate> _myTemplates = [];
  List<GoalTemplate> get myTemplates => _myTemplates;
  List<MedalItem> _medals = [];
  List<MedalItem> get medals => _medals;
  final Map<String, List<RankingEntry>> _rankingByTemplate = {};
  final Map<String, DailyReview> _dailyReviewsByDate = {};
  final Map<String, Set<String>> _reviewedDatesByMonth = {};

  AppState() {
    _api.onUnauthorized = _handleUnauthorized;
  }

  bool isActionPending(String key) => _pendingActions.contains(key);

  bool _startAction(String key) {
    if (_pendingActions.contains(key)) {
      return false;
    }
    _pendingActions.add(key);
    return true;
  }

  void _finishAction(String key) {
    _pendingActions.remove(key);
  }

  void clearGlobalMessage() {
    _globalMessage = null;
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenStorageKey);
    if (savedToken == null || savedToken.isEmpty) return;
    _api.setToken(savedToken);
    _isLoggedIn = true;
    try {
      final me = await _api.getMe();
      _userId = me['id']?.toString();
      _userEmail = me['email']?.toString();
      _userNickname = me['nickname']?.toString();
      _userAvatar = me['avatar']?.toString();
      await fetchGoals();
      await fetchTemplates(silent: true);
      await fetchMedals(silent: true);
      await fetchDailyReviewCalendar(DateTime.now(), silent: true);
      notifyListeners();
    } catch (e) {
      await _clearStoredToken();
      _api.setToken('');
      _isLoggedIn = false;
      _goals = [];
      _userId = null;
      _userEmail = null;
      _userNickname = null;
      _userAvatar = null;
      _timelineByGoal.clear();
      _taskViewsByGoalDate.clear();
      _publicTemplates = [];
      _myTemplates = [];
      _medals = [];
      _rankingByTemplate.clear();
      _dailyReviewsByDate.clear();
      _reviewedDatesByMonth.clear();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _api.login(email, password);
    _api.setToken(result['token']);
    await _persistToken(result['token'].toString());
    _isLoggedIn = true;
    await fetchMe();
    await fetchGoals();
    await fetchTemplates(silent: true);
    await fetchMedals(silent: true);
    await fetchDailyReviewCalendar(DateTime.now(), silent: true);
    notifyListeners();
  }

  Future<void> logout() async {
    _api.setToken('');
    await _clearStoredToken();
    _isLoggedIn = false;
    _goals = [];
    _userId = null;
    _userEmail = null;
    _userNickname = null;
    _userAvatar = null;
    _timelineByGoal.clear();
    _taskViewsByGoalDate.clear();
    _publicTemplates = [];
    _myTemplates = [];
    _medals = [];
    _rankingByTemplate.clear();
    _dailyReviewsByDate.clear();
    _reviewedDatesByMonth.clear();
    notifyListeners();
  }

  void _handleUnauthorized() {
    _api.setToken('');
    _isLoggedIn = false;
    _goals = [];
    _userId = null;
    _userEmail = null;
    _userNickname = null;
    _userAvatar = null;
    _timelineByGoal.clear();
    _taskViewsByGoalDate.clear();
    _publicTemplates = [];
    _myTemplates = [];
    _medals = [];
    _rankingByTemplate.clear();
    _dailyReviewsByDate.clear();
    _reviewedDatesByMonth.clear();
    _globalMessage = '登录状态已过期，请重新登录';
    _pendingActions.clear();
    unawaited(_clearStoredToken());
    notifyListeners();
  }

  Future<void> register(String email, String password, String nickname) async {
    await _api.register(email, password, nickname);
  }

  Future<void> fetchMe() async {
    if (!_isLoggedIn) return;
    try {
      final me = await _api.getMe();
      _userId = me['id']?.toString();
      _userEmail = me['email']?.toString();
      _userNickname = me['nickname']?.toString();
      _userAvatar = me['avatar']?.toString();
    } catch (e) {
      debugPrint('Fetch profile failed: $e');
    }
  }

  Future<void> fetchGoals() async {
    if (!_isLoggedIn) return;
    try {
      final remoteGoalsData = await _api.getGoals();
      _goals = remoteGoalsData.map((data) => Goal.fromJson(data)).toList();
      await _hydrateTimelinesForGoals();
      await _refreshJoinedRankings(silent: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch goals failed: $e');
    }
  }

  Future<void> _hydrateTimelinesForGoals() async {
    _timelineByGoal.clear();
    _taskViewsByGoalDate.clear();
    for (final goal in _goals) {
      await fetchGoalTimeline(goal.id, silent: true);
    }
  }

  Future<void> fetchGoalTimeline(String goalId, {bool silent = false}) async {
    if (!_isLoggedIn) return;
    try {
      final rawDays = await _api.getGoalTimeline(goalId);
      final parsedDays = <TimelineDayView>[];
      final byDate = <String, List<TaskViewItem>>{};

      for (final day in rawDays) {
        final dateStr = day['date']?.toString();
        if (dateStr == null || dateStr.isEmpty) continue;
        final dayNumber = (day['dayNumber'] as num?)?.toInt() ?? 0;
        final List<dynamic> rawTasks = (day['tasks'] as List?) ?? const [];
        final tasks = <TaskViewItem>[];

        for (final rawTask in rawTasks) {
          final task = (rawTask as Map).cast<String, dynamic>();
          final sourceDate = task['sourceDate']?.toString() ?? dateStr;
          final taskIndex = (task['taskIndex'] as num?)?.toInt() ?? 0;
          final key = '$goalId|$sourceDate|$taskIndex';
          tasks.add(TaskViewItem(
            key: key,
            text: task['text']?.toString() ?? '',
            done: task['done'] == true,
            deferred: task['deferred'] == true,
            isMakeup: task['makeup'] == true,
          ));
        }

        final date = _parseDateKey(dateStr);
        parsedDays.add(
            TimelineDayView(date: date, dayNumber: dayNumber, tasks: tasks));
        byDate[dateStr] = tasks;
      }

      _timelineByGoal[goalId] = parsedDays;
      _taskViewsByGoalDate[goalId] = byDate;
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('Fetch timeline failed($goalId): $e');
    }
  }

  Future<void> fetchTemplates({bool silent = false}) async {
    if (!_isLoggedIn) return;
    try {
      final publicData = await _api.getPublicTemplates();
      final myData = await _api.getMyTemplates();
      _publicTemplates = publicData.map(GoalTemplate.fromJson).toList();
      _myTemplates = myData.map(GoalTemplate.fromJson).toList();
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('Fetch templates failed: $e');
    }
  }

  Future<void> fetchMedals({bool silent = false}) async {
    if (!_isLoggedIn) return;
    try {
      final medalData = await _api.getMedals();
      _medals = medalData.map(MedalItem.fromJson).toList()
        ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('Fetch medals failed: $e');
    }
  }

  Future<List<RankingEntry>> fetchRanking(String templateId) async {
    if (!_isLoggedIn) return const [];
    final raw = await _api.getTemplateRanking(templateId);
    final items = raw.map(RankingEntry.fromJson).toList();
    _rankingByTemplate[templateId] = items;
    notifyListeners();
    return items;
  }

  DailyReview? getCachedDailyReview(DateTime date) {
    return _dailyReviewsByDate[_dateKey(date)];
  }

  bool isDailyReviewMonthLoaded(DateTime month) {
    return _reviewedDatesByMonth.containsKey(_monthKey(month));
  }

  bool hasReviewOn(DateTime date) {
    final key = _dateKey(date);
    final monthDates = _reviewedDatesByMonth[_monthKey(date)];
    return _dailyReviewsByDate.containsKey(key) ||
        (monthDates?.contains(key) ?? false);
  }

  Future<DailyReview?> fetchDailyReview(DateTime date,
      {bool silent = false}) async {
    if (!_isLoggedIn) return null;
    final key = _dateKey(date);
    try {
      final raw = await _api.getDailyReview(key);
      if (raw == null) {
        _dailyReviewsByDate.remove(key);
        _reviewedDatesByMonth[_monthKey(date)]?.remove(key);
        if (!silent) notifyListeners();
        return null;
      }
      final review = DailyReview.fromJson(raw);
      _dailyReviewsByDate[key] = review;
      final monthKey = _monthKey(date);
      final monthDates =
          _reviewedDatesByMonth.putIfAbsent(monthKey, () => <String>{});
      monthDates.add(key);
      if (!silent) notifyListeners();
      return review;
    } catch (e) {
      debugPrint('Fetch daily review failed($key): $e');
      rethrow;
    }
  }

  Future<void> fetchDailyReviewCalendar(DateTime month,
      {bool silent = false}) async {
    if (!_isLoggedIn) return;
    final monthText = _monthKey(month);
    try {
      final dates = await _api.getDailyReviewCalendar(monthText);
      _reviewedDatesByMonth[monthText] = dates.toSet();
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('Fetch daily review calendar failed($monthText): $e');
    }
  }

  Future<DailyReview> saveDailyReview(DailyReview review) async {
    if (!_isLoggedIn) {
      throw Exception('Login required');
    }
    final key = _dateKey(review.date);
    final actionKey = 'daily-review:save:$key';
    if (!_startAction(actionKey)) {
      final cached = _dailyReviewsByDate[key];
      if (cached != null) {
        return cached;
      }
      throw Exception('保存进行中，请稍后重试');
    }
    try {
      final payload = {
        'tomorrowTopPriority': review.tomorrowTopPriority,
        'items':
            review.items.map((item) => item.toJson()).toList(growable: false),
      };
      final raw = await _api.upsertDailyReview(key, payload);
      final saved = DailyReview.fromJson(raw);
      _dailyReviewsByDate[key] = saved;
      final monthDates = _reviewedDatesByMonth.putIfAbsent(
        _monthKey(review.date),
        () => <String>{},
      );
      monthDates.add(key);
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('Save daily review failed($key): $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> _refreshJoinedRankings({bool silent = false}) async {
    if (!_isLoggedIn) return;
    final templateIds = _goals
        .where((goal) => goal.templateId != null && goal.joinRanking)
        .map((goal) => goal.templateId!)
        .toSet();
    for (final templateId in templateIds) {
      try {
        final raw = await _api.getTemplateRanking(templateId);
        _rankingByTemplate[templateId] =
            raw.map(RankingEntry.fromJson).toList();
      } catch (e) {
        debugPrint('Fetch ranking failed($templateId): $e');
      }
    }
    if (!silent) notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    if (!_isLoggedIn) return;
    const actionKey = 'goal:create';
    if (!_startAction(actionKey)) return;
    try {
      final created = await _api.createGoal(goal.toJson());
      final createdGoal = Goal.fromJson(created);
      _goals = [createdGoal, ..._goals.where((g) => g.id != createdGoal.id)];
      notifyListeners();
      unawaited(fetchGoalTimeline(createdGoal.id, silent: true));
    } catch (e) {
      debugPrint('Create goal failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> saveGoalEdits(Goal goal) async {
    if (!_isLoggedIn) return;
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) return;
    final actionKey = 'goal:edit:${goal.id}';
    if (!_startAction(actionKey)) return;
    try {
      final updatedData = await _api.updateGoal(goal.id, goal.toJson());
      final updatedGoal = Goal.fromJson(updatedData);
      final latestIndex = _goals.indexWhere((g) => g.id == goal.id);
      if (latestIndex != -1) {
        _goals[latestIndex] = updatedGoal;
      }
      notifyListeners();
      unawaited(fetchGoalTimeline(goal.id, silent: true));
    } catch (e) {
      debugPrint('Save goal edits failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<bool> updateGoalStatus(String id, String status) async {
    if (!_isLoggedIn) return false;
    final actionKey = 'goal:status:$id';
    if (!_startAction(actionKey)) return false;
    final index = _goals.indexWhere((g) => g.id == id);
    String? previousStatus;
    if (index != -1) {
      previousStatus = _goals[index].status;
      _goals[index].status = status;
      notifyListeners();
    }
    try {
      await _api.updateGoal(id, {'status': status.toUpperCase()});
      return true;
    } catch (e) {
      if (index != -1 && previousStatus != null) {
        _goals[index].status = previousStatus;
        notifyListeners();
      }
      debugPrint('Update goal status failed: $e');
      return false;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> deleteGoal(String id) async {
    if (!_isLoggedIn) return;
    final actionKey = 'goal:delete:$id';
    if (!_startAction(actionKey)) return;
    final index = _goals.indexWhere((g) => g.id == id);
    final previousGoal = index == -1 ? null : _goals[index].copyWith();
    final previousTimeline = _timelineByGoal[id];
    final previousTaskViews = _taskViewsByGoalDate[id];
    _goals.removeWhere((g) => g.id == id);
    _timelineByGoal.remove(id);
    _taskViewsByGoalDate.remove(id);
    notifyListeners();
    try {
      await _api.deleteGoal(id);
    } catch (e) {
      if (previousGoal != null) {
        final insertAt = index.clamp(0, _goals.length);
        _goals.insert(insertAt, previousGoal);
      }
      if (previousTimeline != null) {
        _timelineByGoal[id] = previousTimeline;
      }
      if (previousTaskViews != null) {
        _taskViewsByGoalDate[id] = previousTaskViews;
      }
      notifyListeners();
      debugPrint('Delete goal failed: $e');
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<GoalDecomposition> decompose(Goal goal) async {
    if (!_isLoggedIn) {
      throw Exception('Login required for AI decomposition');
    }
    final count = await _todayDecomposeCount();
    if (count >= _dailyAiDecomposeLimit) {
      throw Exception('今天的 AI 拆解次数已达上限（10次），请明天再试');
    }
    final result = await _api.decompose(goal.toJson());
    await _incrementTodayDecomposeCount(count);
    return result;
  }

  Future<void> createTemplateFromGoal(
    Goal goal, {
    required bool isPublic,
    required String tags,
  }) async {
    if (!_isLoggedIn) return;
    final actionKey = 'template:create:${goal.id}';
    if (!_startAction(actionKey)) return;
    try {
      final createdTemplate = GoalTemplate.fromJson(await _api.createTemplate({
        'name': goal.name,
        'description': goal.desc,
        'totalDays': goal.totalDays,
        'visibility': isPublic ? 'PUBLIC' : 'PRIVATE',
        'tags': tags,
        'taskPlan': goal.taskPlan,
      }));
      _myTemplates = [
        createdTemplate,
        ..._myTemplates.where((template) => template.id != createdTemplate.id)
      ];
      notifyListeners();
      unawaited(fetchTemplates(silent: true));
    } catch (e) {
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> publishTemplate(String templateId) async {
    if (!_isLoggedIn) return;
    final actionKey = 'template:publish:$templateId';
    if (!_startAction(actionKey)) return;
    final index =
        _myTemplates.indexWhere((template) => template.id == templateId);
    GoalTemplate? previousTemplate;
    if (index != -1) {
      previousTemplate = _myTemplates[index];
      _myTemplates[index] = previousTemplate.copyWith(
        status: 'PENDING',
        visibility: 'PRIVATE',
      );
      notifyListeners();
    }
    try {
      await _api.publishTemplate(templateId);
      await fetchTemplates();
    } catch (e) {
      if (index != -1 && previousTemplate != null) {
        _myTemplates[index] = previousTemplate;
        notifyListeners();
      }
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> useTemplate(String templateId,
      {required bool joinRanking}) async {
    if (!_isLoggedIn) return;
    final actionKey = 'template:use:$templateId';
    if (!_startAction(actionKey)) return;
    try {
      final createdGoalData = await _api.useTemplate(
        templateId,
        joinRanking: joinRanking,
      );
      final createdGoal = Goal.fromJson(createdGoalData);
      _goals = [
        createdGoal,
        ..._goals.where((goal) => goal.id != createdGoal.id)
      ];
      notifyListeners();
      unawaited(fetchGoalTimeline(createdGoal.id, silent: true));
      if (joinRanking && createdGoal.templateId != null) {
        unawaited(() async {
          try {
            final raw = await _api.getTemplateRanking(createdGoal.templateId!);
            _rankingByTemplate[createdGoal.templateId!] =
                raw.map(RankingEntry.fromJson).toList();
            notifyListeners();
          } catch (e) {
            debugPrint('Fetch ranking after template use failed: $e');
          }
        }());
      }
      unawaited(fetchTemplates(silent: true));
    } catch (e) {
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<String> exportGoalData() async {
    if (!_isLoggedIn) {
      throw Exception('Login required');
    }
    final data = await _api.exportAccountData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> clearHistory() async {
    if (!_isLoggedIn) return;
    const actionKey = 'history:clear';
    if (!_startAction(actionKey)) return;
    final previousGoals = _goals.map((goal) => goal.copyWith()).toList();
    final previousTimeline =
        Map<String, List<TimelineDayView>>.from(_timelineByGoal);
    final previousTaskViews =
        Map<String, Map<String, List<TaskViewItem>>>.from(_taskViewsByGoalDate);
    final previousMedals = List<MedalItem>.from(_medals);
    final previousRankings =
        Map<String, List<RankingEntry>>.from(_rankingByTemplate);
    final previousDailyReviews =
        Map<String, DailyReview>.from(_dailyReviewsByDate);
    final previousReviewCalendar = _reviewedDatesByMonth.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );
    _goals = [];
    _timelineByGoal.clear();
    _taskViewsByGoalDate.clear();
    _medals = [];
    _rankingByTemplate.clear();
    _dailyReviewsByDate.clear();
    _reviewedDatesByMonth.clear();
    notifyListeners();
    try {
      await _api.clearHistory();
      await fetchTemplates(silent: true);
    } catch (e) {
      _goals = previousGoals;
      _timelineByGoal
        ..clear()
        ..addAll(previousTimeline);
      _taskViewsByGoalDate
        ..clear()
        ..addAll(previousTaskViews);
      _medals = previousMedals;
      _rankingByTemplate
        ..clear()
        ..addAll(previousRankings);
      _dailyReviewsByDate
        ..clear()
        ..addAll(previousDailyReviews);
      _reviewedDatesByMonth
        ..clear()
        ..addAll(previousReviewCalendar);
      notifyListeners();
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  String _dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _monthKey(DateTime month) {
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }

  DateTime _parseDateKey(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  _ParsedTaskKey _parseTaskKey(String key) {
    final parts = key.split('|');
    return _ParsedTaskKey(
      goalId: parts[0],
      sourceDate: _parseDateKey(parts[1]),
      taskIndex: int.parse(parts[2]),
    );
  }

  List<TaskViewItem> taskViewsForDate(Goal goal, DateTime date) {
    final goalMap = _taskViewsByGoalDate[goal.id];
    if (goalMap != null) {
      return goalMap[_dateKey(date)] ?? const [];
    }
    return const [];
  }

  List<TimelineDayView> timelineForGoal(Goal goal) {
    return _timelineByGoal[goal.id] ?? const [];
  }

  Future<TaskActionResult> toggleTaskByKey(String key) async {
    if (!_isLoggedIn) return const TaskActionResult();
    final actionKey = 'task:toggle:$key';
    if (!_startAction(actionKey)) return const TaskActionResult();
    final snapshot = _taskSnapshot(key);
    try {
      final parsed = _parseTaskKey(key);
      final goalId = parsed.goalId;
      final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
      final goal = goalIndex == -1 ? null : _goals[goalIndex];
      final targetDone = !(snapshot?.done ?? false);
      final goalWillComplete = targetDone &&
          goal != null &&
          snapshot?.done != true &&
          goalTotalTaskCount(goal) > 0 &&
          goalDoneTaskCount(goal) + 1 >= goalTotalTaskCount(goal);
      _setTaskState(key, done: targetDone, deferred: false);
      notifyListeners();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final source = DateTime(
        parsed.sourceDate.year,
        parsed.sourceDate.month,
        parsed.sourceDate.day,
      );
      await _api.checkIn(goalId, {
        'sourceDate': _dateKey(parsed.sourceDate),
        'taskIndex': parsed.taskIndex,
        'done': targetDone,
        'isMakeup': source.isBefore(today),
      });
      unawaited(fetchGoalTimeline(goalId));
      if (goalWillComplete && goalIndex != -1) {
        _goals[goalIndex] = _goals[goalIndex].copyWith(status: 'completed');
        notifyListeners();
        unawaited(fetchMedals(silent: true));
        return const TaskActionResult(goalCompleted: true);
      }
      return const TaskActionResult();
    } catch (e) {
      _restoreTaskSnapshot(snapshot);
      notifyListeners();
      debugPrint('Toggle task failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> deferTaskByKey(String key, DateTime fromDate) async {
    if (!_isLoggedIn) return;
    final actionKey = 'task:defer:$key';
    if (!_startAction(actionKey)) return;
    final snapshot = _taskSnapshot(key);
    try {
      final parsed = _parseTaskKey(key);
      final goalId = parsed.goalId;
      _setTaskState(key, done: false, deferred: true);
      notifyListeners();
      final target = DateTime(fromDate.year, fromDate.month, fromDate.day)
          .add(const Duration(days: 1));
      await _api.deferTask(goalId, {
        'sourceDate': _dateKey(parsed.sourceDate),
        'taskIndex': parsed.taskIndex,
        'targetDate': _dateKey(target),
      });
      unawaited(fetchGoalTimeline(goalId));
    } catch (e) {
      _restoreTaskSnapshot(snapshot);
      notifyListeners();
      debugPrint('Defer task failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  TaskViewItem? _taskSnapshot(String key) {
    final parsed = _parseTaskKey(key);
    final dateKey = _dateKey(parsed.sourceDate);
    final tasks = _taskViewsByGoalDate[parsed.goalId]?[dateKey];
    if (tasks == null) return null;
    for (final task in tasks) {
      if (task.key == key) return task;
    }
    return null;
  }

  void _restoreTaskSnapshot(TaskViewItem? snapshot) {
    if (snapshot == null) return;
    _replaceTaskInCaches(snapshot.key, (_) => snapshot);
  }

  void _setTaskState(String key, {required bool done, required bool deferred}) {
    _replaceTaskInCaches(
      key,
      (task) => task.copyWith(done: done, deferred: deferred),
    );
  }

  void _replaceTaskInCaches(
      String key, TaskViewItem Function(TaskViewItem task) transform) {
    final parsed = _parseTaskKey(key);
    final dateKey = _dateKey(parsed.sourceDate);

    final goalMap = _taskViewsByGoalDate[parsed.goalId];
    if (goalMap != null) {
      final tasks = goalMap[dateKey];
      if (tasks != null) {
        goalMap[dateKey] = tasks
            .map((task) => task.key == key ? transform(task) : task)
            .toList(growable: false);
      }
    }

    final timeline = _timelineByGoal[parsed.goalId];
    if (timeline != null) {
      _timelineByGoal[parsed.goalId] = timeline.map((day) {
        if (_dateKey(day.date) != dateKey) return day;
        return TimelineDayView(
          date: day.date,
          dayNumber: day.dayNumber,
          tasks: day.tasks
              .map((task) => task.key == key ? transform(task) : task)
              .toList(growable: false),
        );
      }).toList(growable: false);
    }
  }

  int goalTotalTaskCount(Goal goal) {
    return goal.taskPlan.fold<int>(0, (sum, day) => sum + day.length);
  }

  int goalDoneTaskCount(Goal goal) {
    final timeline = _timelineByGoal[goal.id];
    if (timeline == null || timeline.isEmpty) return 0;
    final doneKeys = <String>{};
    for (final day in timeline) {
      for (final task in day.tasks) {
        if (task.done) {
          doneKeys.add(task.key);
        }
      }
    }
    return doneKeys.length;
  }

  int goalProgressPercent(Goal goal) {
    final total = goalTotalTaskCount(goal);
    if (total == 0) return 0;
    final done = goalDoneTaskCount(goal);
    return ((done / total) * 100).round();
  }

  bool hasJoinedRanking(String templateId) {
    return _goals
        .any((goal) => goal.templateId == templateId && goal.joinRanking);
  }

  bool hasUsedTemplate(String templateId) {
    return _goals.any((goal) => goal.templateId == templateId);
  }

  RankingEntry? currentUserRankingEntry(String templateId) {
    final currentUserId = _userId;
    if (currentUserId == null) return null;
    final entries = _rankingByTemplate[templateId];
    if (entries == null) return null;
    for (final entry in entries) {
      if (entry.userId == currentUserId) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, token);
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
  }

  String _todayDecomposeStorageKey() {
    final now = DateTime.now();
    final userKey = _userId ?? _userEmail ?? 'guest';
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '$_aiDecomposeCountKeyPrefix:$userKey:$dateKey';
  }

  Future<int> _todayDecomposeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayDecomposeStorageKey()) ?? 0;
  }

  Future<void> _incrementTodayDecomposeCount(int currentCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_todayDecomposeStorageKey(), currentCount + 1);
  }

  Future<void> shareProgress(BuildContext context,
      {required int streak}) async {
    final screenshotController = ScreenshotController();

    // Calculate stats for the share card
    final activeGoals = _goals.where((g) => g.isActive).toList();
    final int doneTasks =
        activeGoals.fold<int>(0, (a, g) => a + goalDoneTaskCount(g));
    final int totalTasks =
        activeGoals.fold<int>(0, (a, g) => a + goalTotalTaskCount(g));
    final String nickname =
        _userNickname ?? _userEmail?.split('@').first ?? 'GoalFlow 用户';

    try {
      final image = await screenshotController.captureFromWidget(
        Material(
          child: ShareCard(
            goals: activeGoals,
            doneTasks: doneTasks,
            totalTasks: totalTasks,
            streak: streak,
            nickname: nickname,
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      final tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/goalflow_share.png';
      final file = File(filePath);

      // Ensure the directory exists
      await file.parent.create(recursive: true);
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: '我在 GoalFlow 坚持打卡，这是我的今日战报！🎯',
      );
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }
}
