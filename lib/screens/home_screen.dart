import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/completion_ceremony.dart';
import 'daily_review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  int _tab = 0; // 0=pending 1=done 2=deferred

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<AppState>()
          .fetchDailyReviewCalendar(_selectedDate, silent: true);
    });
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday {
    final s =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return s == _today;
  }

  List<DateTime> get _weekDates {
    final now = _today;
    final weekday = now.weekday;
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
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildWeekStrip()),
            SliverToBoxAdapter(child: _buildDailyReviewCard(state)),
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

  Widget _buildHeader() {
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
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 10)
                ],
              ),
              child: const Center(
                  child: Text('☀', style: TextStyle(fontSize: 18))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final week = _weekDates;
    final weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
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
              onTap: () {
                setState(() => _selectedDate = date);
                context
                    .read<AppState>()
                    .fetchDailyReviewCalendar(date, silent: true);
              },
              child: Column(
                children: [
                  Text(
                    '周${weekLabels[i]}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.text : AppColors.sub,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.sub,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4,
                    height: 4,
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
    int pending = 0, done = 0, deferred = 0;
    for (final g in goals) {
      final items = state.taskViewsForDate(g, _selectedDate);
      pending += items.where((t) => !t.done && !t.deferred).length;
      done += items.where((t) => t.done).length;
      deferred += items.where((t) => !t.done && t.deferred).length;
    }

    final labels = [
      '待完成 · $pending',
      '已完成 · $done',
      '已顺延 · $deferred',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Row(
        children: List.generate(
            3,
            (i) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            _tab == i ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              _tab == i ? FontWeight.w700 : FontWeight.w400,
                          color: _tab == i ? Colors.white : AppColors.sub,
                        ),
                      ),
                    ),
                  ),
                )),
      ),
    );
  }

  Widget _buildDailyReviewCard(AppState state) {
    final hasReview = state.hasReviewOn(_selectedDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasReview ? AppColors.accent : AppColors.pill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasReview ? Icons.check_rounded : Icons.edit_note_rounded,
              color: hasReview ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasReview ? '今日复盘已完成' : '今日复盘',
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  hasReview ? '可以回看今天四个维度的状态，也可以继续修改。' : '花一分钟复盘工作、健康、人际关系和爱好。',
                  style:
                      AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DailyReviewScreen(initialDate: _selectedDate),
                ),
              );
              if (!mounted) return;
              await context.read<AppState>().fetchDailyReviewCalendar(
                    _selectedDate,
                    silent: true,
                  );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text,
              backgroundColor: AppColors.pill,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(hasReview ? '查看 / 编辑' : '开始复盘'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(AppState state, List<Goal> goals) {
    if (goals.isEmpty) {
      return _EmptyState(message: '还没有目标，去添加一个吧 🎯');
    }

    final displayGoals = goals.where((g) {
      final items = state.taskViewsForDate(g, _selectedDate);
      if (_tab == 0) return items.any((t) => !t.done && !t.deferred);
      if (_tab == 1) return items.any((t) => t.done);
      return items.any((t) => !t.done && t.deferred);
    }).toList();

    if (displayGoals.isEmpty) {
      final msgs = ['今天没有任务', '暂无已完成任务', '暂无顺延任务'];
      return _EmptyState(message: msgs[_tab]);
    }

    return Column(
      children: displayGoals.map<Widget>((g) {
        return _GoalSection(
          key: ValueKey(g.id),
          goal: g,
          selectedDate: _selectedDate,
          tab: _tab,
        );
      }).toList(),
    );
  }
}

class _GoalSection extends StatefulWidget {
  final Goal goal;
  final DateTime selectedDate;
  final int tab;

  const _GoalSection({
    super.key,
    required this.goal,
    required this.selectedDate,
    required this.tab,
  });

  @override
  State<_GoalSection> createState() => _GoalSectionState();
}

class _GoalSectionState extends State<_GoalSection> {
  bool _collapsed = false;

  Future<void> _handleToggleTask(AppState state, TaskViewItem task) async {
    try {
      final result = await state.toggleTaskByKey(task.key);
      if (!mounted) return;
      if (result.goalCompleted) {
        showToast(context, '目标已完成，已获得勋章');
        showCompletionCeremony(context);
      } else {
        showToast(context, task.done ? '已取消完成' : '已完成任务');
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }

  Future<void> _handleDeferTask(AppState state, TaskViewItem task) async {
    showToast(context, '已顺延任务');
    try {
      await state.deferTaskByKey(task.key, widget.selectedDate);
    } catch (e) {
      if (!mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.goal;
    final state = context.watch<AppState>();
    final liveGoal =
        state.goals.firstWhere((x) => x.id == g.id, orElse: () => g);
    final progressPercent = state.goalProgressPercent(liveGoal);
    final allItems = state.taskViewsForDate(liveGoal, widget.selectedDate);
    final tasks = allItems.where((item) {
      if (widget.tab == 0) return !item.done && !item.deferred;
      if (widget.tab == 1) return item.done;
      return !item.done && item.deferred;
    }).toList();

    final today = DateTime.now();
    final isToday = widget.selectedDate.day == today.day &&
        widget.selectedDate.month == today.month &&
        widget.selectedDate.year == today.year;
    final isPast = DateTime(widget.selectedDate.year, widget.selectedDate.month,
            widget.selectedDate.day)
        .isBefore(DateTime(today.year, today.month, today.day));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child:
                        Icon(Icons.expand_more, size: 18, color: AppColors.sub),
                  ),
                  const SizedBox(width: 6),
                  Text('${g.emoji} ${g.name}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const Spacer(),
                  if (isPast && !isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.pill,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('可补卡',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 8),
                  Text('$progressPercent%', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          if (!_collapsed)
            ...tasks.asMap().entries.map((e) {
              final task = e.value;
              return TaskCheckTile(
                text: task.text,
                done: task.done,
                deferred: task.deferred,
                isMakeup: task.isMakeup,
                fontSize: 12,
                onToggle: () => _handleToggleTask(state, task),
                onDefer: isToday && !task.done
                    ? () => _handleDeferTask(state, task)
                    : null,
                showDivider: e.key < tasks.length - 1,
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
        child: Center(
            child: Text(message,
                style: AppTextStyles.caption.copyWith(fontSize: 14))),
      );
}
