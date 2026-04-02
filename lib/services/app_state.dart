import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/goal_decomposition.dart';
import '../models/habit.dart';
import '../models/daily_review.dart';
import '../services/api_service.dart';
import '../services/reminder_service.dart';

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
  static const _reminderEnabledStorageKey = 'daily_reminder_enabled';
  static const _reminderHourStorageKey = 'daily_reminder_hour';
  static const _reminderMinuteStorageKey = 'daily_reminder_minute';
  final ApiService _api = ApiService();
  String? _globalMessage;

  List<Goal> _goals = [];
  List<Goal> get goals => _goals;
  List<Habit> _habits = [];
  List<Habit> get habits => _habits;
  String? get globalMessage => _globalMessage;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _userId;
  String? _userEmail;
  String? _userNickname;
  String? _userAvatar;
  DateTime? _userCreatedAt;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userNickname => _userNickname;
  String? get userAvatar => _userAvatar;
  DateTime? get userCreatedAt => _userCreatedAt;

  final Map<String, List<TimelineDayView>> _timelineByGoal = {};
  final Map<String, Map<String, List<TaskViewItem>>> _taskViewsByGoalDate = {};
  final Set<String> _pendingActions = <String>{};
  final Map<String, DailyReview> _dailyReviewsByDate = {};
  final Map<String, Set<String>> _reviewedDatesByMonth = {};
  final Map<String, Set<String>> _habitDoneDatesByMonth = {};
  bool _reminderEnabled = false;
  int _reminderHour = 19;
  int _reminderMinute = 0;
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);
  String get reminderTimeLabel =>
      '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}';

  int get reviewedDatesCount {
    final allDates = <String>{};
    for (final monthSet in _reviewedDatesByMonth.values) {
      allDates.addAll(monthSet);
    }
    return allDates.length;
  }

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

  Future<void> initializeLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderEnabled = prefs.getBool(_reminderEnabledStorageKey) ?? false;
    _reminderHour = prefs.getInt(_reminderHourStorageKey) ?? 19;
    _reminderMinute = prefs.getInt(_reminderMinuteStorageKey) ?? 0;
    if (_reminderEnabled) {
      await ReminderService.instance.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    } else {
      await ReminderService.instance.cancelDailyReminder();
    }
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenStorageKey);
    if (savedToken == null || savedToken.isEmpty) return;
    _api.setToken(savedToken);
    _isLoggedIn = true;
    try {
      final me = await _api.getMe();
      _applyProfileData(me);
      await fetchGoals();
      await fetchHabits(silent: true);
      await fetchDailyReviewCalendar(DateTime.now(), silent: true);
      notifyListeners();
    } catch (e) {
      await _clearStoredToken();
      _api.setToken('');
      _resetSessionState();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _api.login(email, password);
    _api.setToken(result['token']);
    await _persistToken(result['token'].toString());
    _isLoggedIn = true;
    await fetchMe();
    await fetchGoals();
    await fetchHabits(silent: true);
    await fetchDailyReviewCalendar(DateTime.now(), silent: true);
    notifyListeners();
  }

  Future<void> logout() async {
    _api.setToken('');
    await _clearStoredToken();
    _resetSessionState();
    notifyListeners();
  }

  void _handleUnauthorized() {
    _api.setToken('');
    _resetSessionState(globalMessage: '登录状态已过期，请重新登录');
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
      _applyProfileData(me);
    } catch (e) {
      debugPrint('Fetch profile failed: $e');
    }
  }

  Future<void> updateProfile({
    String? nickname,
    String? avatar,
  }) async {
    if (!_isLoggedIn) return;
    const actionKey = 'user:update_profile';
    if (!_startAction(actionKey)) return;
    try {
      final payload = <String, dynamic>{};
      if (nickname != null) payload['nickname'] = nickname;

      if (avatar != null) {
        // 剥离 Data URL 前缀 (如 data:image/jpeg;base64,)
        String pureBase64 = avatar;
        if (pureBase64.contains(',')) {
          pureBase64 = pureBase64.substring(pureBase64.indexOf(',') + 1);
        }
        payload['avatar'] = pureBase64;
      }

      if (payload.isEmpty) return;

      final result = await _api.updateProfile(payload);
      _userNickname = result['nickname']?.toString();
      _userAvatar = _api.resolveAssetUrl(result['avatar']?.toString());
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> fetchGoals() async {
    if (!_isLoggedIn) return;
    try {
      final remoteGoalsData = await _api.getGoals();
      _goals = remoteGoalsData.map((data) => Goal.fromJson(data)).toList();
      await _hydrateTimelinesForGoals();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch goals failed: $e');
    }
  }

  Future<void> fetchHabits({bool silent = false}) async {
    if (!_isLoggedIn) return;
    try {
      final raw = await _api.getHabits();
      _habits = raw.map(Habit.fromJson).toList();
      await fetchHabitCalendar(DateTime.now(), silent: true);
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('Fetch habits failed: $e');
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

  bool isHabitMonthLoaded(DateTime month) {
    return _habitDoneDatesByMonth.containsKey(_monthKey(month));
  }

  bool hasHabitDoneOn(DateTime date) {
    final key = _dateKey(date);
    return _habitDoneDatesByMonth[_monthKey(date)]
            ?.any((item) => item.endsWith('|$key')) ??
        false;
  }

  int doneHabitCountOn(DateTime date) {
    final key = _dateKey(date);
    return _habits.where((habit) => isHabitDoneOnDate(habit.id, key)).length;
  }

  int totalHabitCountOn(DateTime date) {
    return _habits.where((habit) {
      if (!habit.isActive) return false;
      // Only count habits that were created on or before this date
      if (habit.createdAt != null && habit.createdAt!.isAfter(date)) {
        return false;
      }
      return true;
    }).length;
  }

  Future<void> fetchHabitCalendar(DateTime month, {bool silent = false}) async {
    if (!_isLoggedIn) return;
    final monthText = _monthKey(month);
    try {
      final checkins = await _api.getHabitCheckins(monthText);
      final doneDates = <String>{};
      for (final item in checkins) {
        final date = item['date']?.toString();
        final habitId = item['habitId']?.toString();
        if (habitId != null &&
            habitId.isNotEmpty &&
            date != null &&
            date.isNotEmpty) {
          doneDates.add('$habitId|$date');
        }
      }
      _habitDoneDatesByMonth[monthText] = doneDates;
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('Fetch habit calendar failed($monthText): $e');
    }
  }

  Future<void> addHabit({
    required String name,
    String? category,
  }) async {
    if (!_isLoggedIn) return;
    const actionKey = 'habit:create';
    if (!_startAction(actionKey)) return;
    try {
      final created = await _api.createHabit({
        'name': name,
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      });
      final habit = Habit.fromJson(created);
      _habits = [habit, ..._habits.where((item) => item.id != habit.id)];
      notifyListeners();
    } catch (e) {
      debugPrint('Create habit failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> updateHabit(
    Habit habit, {
    required String name,
    String? category,
  }) async {
    if (!_isLoggedIn) return;
    final actionKey = 'habit:update:${habit.id}';
    if (!_startAction(actionKey)) return;
    try {
      final updated = await _api.updateHabit(habit.id, {
        'name': name,
        'category': category?.trim().isEmpty == true ? null : category?.trim(),
      });
      final parsed = Habit.fromJson(updated);
      final index = _habits.indexWhere((item) => item.id == habit.id);
      if (index != -1) {
        _habits[index] = parsed.copyWith(todayDone: _habits[index].todayDone);
      }
      notifyListeners();
      unawaited(fetchHabits(silent: true));
    } catch (e) {
      debugPrint('Update habit failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    if (!_isLoggedIn) return;
    final actionKey = 'habit:delete:$habitId';
    if (!_startAction(actionKey)) return;
    final previous = List<Habit>.from(_habits);
    _habits.removeWhere((habit) => habit.id == habitId);
    notifyListeners();
    try {
      await _api.deleteHabit(habitId);
      unawaited(fetchHabitCalendar(DateTime.now(), silent: true));
    } catch (e) {
      _habits = previous;
      notifyListeners();
      debugPrint('Delete habit failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
    }
  }

  Future<void> toggleHabit(Habit habit, DateTime date) async {
    if (!_isLoggedIn) return;
    final dateKey = _dateKey(date);
    final actionKey = 'habit:toggle:${habit.id}:$dateKey';
    if (!_startAction(actionKey)) return;
    final monthKey = _monthKey(date);
    final monthSet =
        _habitDoneDatesByMonth.putIfAbsent(monthKey, () => <String>{});
    final wasDone = monthSet.contains('${habit.id}|$dateKey');
    final nextDone = !wasDone;
    final previousMonthSet = Set<String>.from(monthSet);
    final previousHabits = List<Habit>.from(_habits);

    if (nextDone) {
      monthSet.add('${habit.id}|$dateKey');
    } else {
      monthSet.remove('${habit.id}|$dateKey');
    }
    _applyHabitToggleLocal(habit.id, date, nextDone);
    notifyListeners();
    try {
      await _api.setHabitCheckin(habit.id, dateKey, nextDone);
      unawaited(fetchHabits(silent: true));
      unawaited(fetchHabitCalendar(date, silent: true));
    } catch (e) {
      _habitDoneDatesByMonth[monthKey] = previousMonthSet;
      _habits = previousHabits;
      notifyListeners();
      debugPrint('Toggle habit failed: $e');
      rethrow;
    } finally {
      _finishAction(actionKey);
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

  Future<void> addGoal(Goal goal) async {
    if (!_isLoggedIn) return;
    const actionKey = 'goal:create';
    if (!_startAction(actionKey)) return;
    try {
      final created = await _api.createGoal(goal.toJson());
      final createdGoal = Goal.fromJson(created);
      _goals = [createdGoal, ..._goals.where((g) => g.id != createdGoal.id)];
      notifyListeners();
      await fetchGoalTimeline(createdGoal.id, silent: false);
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
      await fetchGoalTimeline(goal.id, silent: false);
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
    final previousHabits = List<Habit>.from(_habits);
    final previousTimeline =
        Map<String, List<TimelineDayView>>.from(_timelineByGoal);
    final previousTaskViews =
        Map<String, Map<String, List<TaskViewItem>>>.from(_taskViewsByGoalDate);
    final previousDailyReviews =
        Map<String, DailyReview>.from(_dailyReviewsByDate);
    final previousReviewCalendar = _reviewedDatesByMonth.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );
    final previousHabitCalendar = _habitDoneDatesByMonth.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );
    _goals = [];
    _habits = [];
    _timelineByGoal.clear();
    _taskViewsByGoalDate.clear();
    _dailyReviewsByDate.clear();
    _reviewedDatesByMonth.clear();
    _habitDoneDatesByMonth.clear();
    notifyListeners();
    try {
      await _api.clearHistory();
    } catch (e) {
      _goals = previousGoals;
      _habits = previousHabits;
      _timelineByGoal
        ..clear()
        ..addAll(previousTimeline);
      _taskViewsByGoalDate
        ..clear()
        ..addAll(previousTaskViews);
      _dailyReviewsByDate
        ..clear()
        ..addAll(previousDailyReviews);
      _reviewedDatesByMonth
        ..clear()
        ..addAll(previousReviewCalendar);
      _habitDoneDatesByMonth
        ..clear()
        ..addAll(previousHabitCalendar);
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

  void _applyProfileData(Map<String, dynamic> me) {
    _userId = me['id']?.toString();
    _userEmail = me['email']?.toString();
    _userNickname = me['nickname']?.toString();
    _userAvatar = _api.resolveAssetUrl(me['avatar']?.toString());
    _userCreatedAt = me['createdAt'] != null
        ? DateTime.parse(me['createdAt'].toString())
        : null;
  }

  void _resetSessionState({String? globalMessage}) {
    _isLoggedIn = false;
    _goals = [];
    _habits = [];
    _userId = null;
    _userEmail = null;
    _userNickname = null;
    _userAvatar = null;
    _userCreatedAt = null;
    _timelineByGoal.clear();
    _taskViewsByGoalDate.clear();
    _dailyReviewsByDate.clear();
    _reviewedDatesByMonth.clear();
    _habitDoneDatesByMonth.clear();
    _pendingActions.clear();
    _globalMessage = globalMessage;
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

  List<Habit> activeHabitsForDate(DateTime date) {
    final key = _dateKey(date);
    return _habits
        .where((habit) => habit.isActive)
        .map((habit) => habit.copyWith(
              todayDone: isHabitDoneOnDate(habit.id, key),
            ))
        .toList(growable: false);
  }

  bool isHabitDoneOnDate(String habitId, String dateKey) {
    final month = dateKey.substring(0, 7);
    return _habitDoneDatesByMonth[month]?.contains('$habitId|$dateKey') ??
        false;
  }

  int habitStreak(Habit habit) {
    return _habits
        .firstWhere((item) => item.id == habit.id, orElse: () => habit)
        .streak;
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

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, token);
  }

  void _applyHabitToggleLocal(String habitId, DateTime date, bool isDone) {
    final dateKey = _dateKey(date);
    final todayKey = _dateKey(DateTime.now());
    final index = _habits.indexWhere((habit) => habit.id == habitId);
    if (index == -1) return;
    final current = _habits[index];
    _habits[index] = current.copyWith(
      todayDone: dateKey == todayKey ? isDone : current.todayDone,
      streak: dateKey == todayKey
          ? _estimateHabitStreak(habitId, todayKey, isDone)
          : current.streak,
    );
  }

  int _estimateHabitStreak(String habitId, String dateKey, bool isDone) {
    final doneDates = <DateTime>{};
    for (final entry in _habitDoneDatesByMonth.entries) {
      for (final value in entry.value) {
        final parts = value.split('|');
        if (parts.length == 2 && parts[0] == habitId) {
          doneDates.add(_parseDateKey(parts[1]));
        }
      }
    }
    final targetDate = _parseDateKey(dateKey);
    if (isDone) {
      doneDates.add(targetDate);
    } else {
      doneDates.remove(targetDate);
    }
    if (doneDates.isEmpty) {
      return 0;
    }
    final sorted = doneDates.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    if (sorted.first != normalizedToday) {
      return 0;
    }
    var streak = 1;
    var cursor = sorted.first;
    for (var i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (next == cursor.subtract(const Duration(days: 1))) {
        streak += 1;
        cursor = next;
        continue;
      }
      break;
    }
    return streak;
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

  Future<bool> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      final granted = await ReminderService.instance.requestPermission();
      if (!granted) {
        return false;
      }
      await ReminderService.instance.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    } else {
      await ReminderService.instance.cancelDailyReminder();
    }
    _reminderEnabled = enabled;
    await prefs.setBool(_reminderEnabledStorageKey, enabled);
    notifyListeners();
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    _reminderHour = time.hour;
    _reminderMinute = time.minute;
    await prefs.setInt(_reminderHourStorageKey, _reminderHour);
    await prefs.setInt(_reminderMinuteStorageKey, _reminderMinute);
    if (_reminderEnabled) {
      await ReminderService.instance.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    }
    notifyListeners();
  }
}
