import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../models/day_record.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Selected date — defaults to today
  DateTime _selectedDate = DateTime.now();
  int _tab = 0; // 0=pending 1=done 2=deferred

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday {
    final s = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return s == _today;
  }

  // Build week dates (Mon-Sun of the week containing today)
  List<DateTime> get _weekDates {
    final now = _today;
    final weekday = now.weekday; // 1=Mon
    final monday = now.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.goals.where((g) => g.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(goals)),
            SliverToBoxAdapter(child: _buildWeekStrip()),
            SliverToBoxAdapter(child: _buildTabs(state, goals)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _buildTaskList(state, goals),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<Goal> goals) {
    final pending = goals.fold<int>(0, (acc, g) {
      // rough count for selected date
      return acc + g.tasksForDate(_selectedDate).length;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你好 👋', style: AppTextStyles.headline),
                const SizedBox(height: 4),
                Text(
                  _isToday
                      ? '今天，${DateFormat('M月d日').format(_selectedDate)}'
                      : DateFormat('M月d日 EEEE', 'zh').format(_selectedDate),
                  style: AppTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic, fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
              ),
              child: const Center(child: Text('☀', style: TextStyle(fontSize: 18))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final week = _weekDates;
    final weekLabels = ['一','二','三','四','五','六','日'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Row(
        children: List.generate(7, (i) {
          final date = week[i];
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;
          final isToday = date == _today;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Column(
                children: [
                  Text(
                    '周${weekLabels[i]}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.text : AppColors.sub,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.sub,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabs(AppState state, List<Goal> goals) {
    // Count tasks for selected date
    int pending = 0, done = 0, deferred = 0;
    for (final g in goals) {
      final r = state.getRecord(g.id, _selectedDate);
      if (r != null) {
        for (final t in r.tasks) {
          if (t.isDeferred) deferred++;
          else if (t.isDone) done++;
          else pending++;
        }
      } else {
        pending += g.tasksForDate(_selectedDate).length;
      }
    }

    final labels = [
      '待完成 · $pending', '已完成 · $done', '已顺延 · $deferred',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _tab == i ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w400,
                  color: _tab == i ? Colors.white : AppColors.sub,
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildTaskList(AppState state, List<Goal> goals) {
    if (goals.isEmpty) {
      return _EmptyState(message: '还没有目标，去添加一个吧 🎯');
    }

    return FutureBuilder<List<_GoalDayData>>(
      future: _loadDayData(state, goals),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data!;

        // Filter by tab
        final filtered = data.map((gd) {
          List<_TaskItem> tasks;
          if (_tab == 0) tasks = gd.tasks.where((t) => !t.record.isDone && !t.record.isDeferred).toList();
          else if (_tab == 1) tasks = gd.tasks.where((t) => t.record.isDone).toList();
          else tasks = gd.tasks.where((t) => t.record.isDeferred).toList();
          return _GoalDayData(
            goal: gd.goal,
            dayRecord: gd.dayRecord,
            tasks: tasks,
            progressPercent: gd.progressPercent,
          );
        }).where((gd) => gd.tasks.isNotEmpty).toList();

        if (filtered.isEmpty) {
          final msgs = ['今日任务全部完成 🎉', '暂无已完成任务', '暂无顺延任务'];
          return _EmptyState(message: msgs[_tab]);
        }

        return Column(
          children: filtered.map<Widget>((gd) => _GoalSection(
            key: ValueKey(gd.goal.id),
            goalData: gd,
            selectedDate: _selectedDate,
            onToggle: (idx) async {
              final t = gd.tasks[idx].record;
              if (t.isDone) {
                await state.uncheck(gd.goal, _selectedDate, gd.tasks[idx].index);
              } else {
                // If past date, it's a makeup checkin
                // final isMakeup = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day) < _today;
                final isMakeup =DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).isBefore(_today);
                await state.checkIn(gd.goal, _selectedDate, gd.tasks[idx].index, isMakeup: isMakeup);
                if (mounted) showToast(context, isMakeup ? '补卡成功 ✓' : '打卡成功 ✓');
              }
              setState(() {});
            },
            onDefer: (idx) async {
              await state.deferTask(gd.goal, _selectedDate, gd.tasks[idx].index);
              if (mounted) showToast(context, '已顺延至明日');
              setState(() {});
            },
          )).toList(),
        );
      },
    );
  }

  Future<List<_GoalDayData>> _loadDayData(AppState state, List<Goal> goals) async {
    final result = <_GoalDayData>[];
    for (final g in goals) {
      final record = await state.getOrCreateRecord(g, _selectedDate);
      final tasks = record.tasks.asMap().entries.map((e) =>
        _TaskItem(index: e.key, record: e.value)).toList();
      final completedDays = state.getRecordsForGoal(g.id).where((r) => r.allDone).length;
      final progressPercent = g.totalDays > 0 ? ((completedDays / g.totalDays) * 100).round() : 0;
      result.add(_GoalDayData(
        goal: g,
        dayRecord: record,
        tasks: tasks,
        progressPercent: progressPercent,
      ));
    }
    return result;
  }
}

class _GoalDayData {
  final Goal goal;
  final DayRecord dayRecord;
  final List<_TaskItem> tasks;
  final int progressPercent;
  _GoalDayData({
    required this.goal,
    required this.dayRecord,
    required this.tasks,
    required this.progressPercent,
  });
}

class _TaskItem {
  final int index;
  final TaskRecord record;
  _TaskItem({required this.index, required this.record});
}

class _GoalSection extends StatefulWidget {
  final _GoalDayData goalData;
  final DateTime selectedDate;
  final void Function(int) onToggle;
  final void Function(int) onDefer;

  const _GoalSection({
    super.key,
    required this.goalData, required this.selectedDate,
    required this.onToggle, required this.onDefer,
  });

  @override
  State<_GoalSection> createState() => _GoalSectionState();
}

class _GoalSectionState extends State<_GoalSection> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.goalData.goal;
    final tasks = widget.goalData.tasks;
    final state = context.watch<AppState>();
    final liveGoal = state.goals.firstWhere(
      (x) => x.id == g.id,
      orElse: () => g,
    );
    final progressPercent = state.getGoalProgressPercent(liveGoal);
    final today = DateTime.now();
    final isToday = widget.selectedDate.day == today.day &&
        widget.selectedDate.month == today.month &&
        widget.selectedDate.year == today.year;
    final isPast = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day)
        .isBefore(DateTime(today.year, today.month, today.day));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)],
      ),
      child: Column(
        children: [
          // Group header
          GestureDetector(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 18, color: AppColors.sub),
                  ),
                  const SizedBox(width: 6),
                  Text('${g.emoji} ${g.name}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const Spacer(),
                  if (isPast && !isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(10)),
                      child: Text('可补卡', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 8),
                  Text('$progressPercent%', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          if (!_collapsed)
            ...tasks.asMap().entries.map((e) {
              final i = e.key;
              final task = e.value;
              return TaskCheckTile(
                text: task.record.taskText,
                done: task.record.isDone,
                deferred: task.record.isDeferred,
                isMakeup: task.record.isMakeup,
                fontSize: 12,
                onToggle: () => widget.onToggle(i),
                onDefer: isToday ? () => widget.onDefer(i) : null,
                showDivider: i < tasks.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text(message, style: AppTextStyles.caption.copyWith(fontSize: 14))),
  );
}
