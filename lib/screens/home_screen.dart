import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/completion_ceremony.dart';
import 'habits_screen.dart';
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
      context.read<AppState>().fetchHabitCalendar(_selectedDate, silent: true);
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

            // 支柱一：今日习惯
            SliverToBoxAdapter(
              child: _buildSectionTitle('今日习惯', '🔄'),
            ),
            SliverToBoxAdapter(child: _buildHabitCard(state)),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 支柱二：今日复盘
            SliverToBoxAdapter(
              child: _buildSectionTitle('今日复盘', '📝'),
            ),
            SliverToBoxAdapter(child: _buildDailyReviewCard(state)),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 支柱三：今日目标 (只看待办)
            SliverToBoxAdapter(
              child: _buildSectionTitle('今日目标', '🎯'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTaskList(state, goals),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.text.withOpacity(0.8),
            ),
          ),
        ],
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
                context.read<AppState>().fetchHabitCalendar(date, silent: true);
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasReview ? '今日复盘已完成' : '去复盘',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  hasReview ? '记录了生活，就留住了时间。' : '理解今天，开启明天。',
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
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
            child: Text(hasReview ? '查看' : '开始'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(AppState state) {
    final habits = state.activeHabitsForDate(_selectedDate);
    final doneCount = habits.where((habit) => habit.todayDone).length;
    final totalCount = habits.length;
    final displayHabits = habits.take(3).toList(growable: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日习惯',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCount == 0
                          ? '还没有习惯记录'
                          : '已完成 $doneCount / $totalCount',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final appState = context.read<AppState>();
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HabitsScreen()),
                  );
                  if (!mounted) return;
                  await appState.fetchHabits(silent: true);
                  await appState.fetchHabitCalendar(_selectedDate,
                      silent: true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text,
                  backgroundColor: AppColors.pill,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('管理'),
              ),
            ],
          ),
          if (displayHabits.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...displayHabits.asMap().entries.map((entry) {
              final habit = entry.value;
              return _HabitQuickTile(
                habit: habit,
                date: _selectedDate,
                showDivider: entry.key < displayHabits.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskList(AppState state, List<Goal> goals) {
    if (goals.isEmpty) {
      return const _EmptyState(message: '还没有创建目标，去看看你想做成一件什么事。');
    }

    final pendingGoals = goals.where((g) {
      final items = state.taskViewsForDate(g, _selectedDate);
      return items.any((t) => !t.done && !t.deferred);
    }).toList();

    if (pendingGoals.isEmpty) {
      return _EmptyState(message: '今日目标已全部达成 ✨');
    }

    return Column(
      children: pendingGoals.map<Widget>((g) {
        return _GoalSection(
          key: ValueKey(g.id),
          goal: g,
          selectedDate: _selectedDate,
          tab: 0, // 强制显示待完成
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

class _HabitQuickTile extends StatelessWidget {
  final Habit habit;
  final DateTime date;
  final bool showDivider;

  const _HabitQuickTile({
    required this.habit,
    required this.date,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDone = habit.todayDone == true;
    final isToday = DateTime(date.year, date.month, date.day) ==
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    await context.read<AppState>().toggleHabit(habit, date);
                    if (!context.mounted) return;
                    showToast(context, isDone ? '已取消打卡' : '已完成习惯');
                  } catch (e) {
                    if (!context.mounted) return;
                    showToast(context, userErrorMessage(e));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  child: CheckGlyph(
                    checked: isDone,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDone ? AppColors.sub : AppColors.text,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      habit.category?.toString().isNotEmpty == true
                          ? habit.category.toString()
                          : (isToday ? '今天完成一次就够' : '这一天的习惯记录'),
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.accentLight : AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.habitStreak(habit)}天',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.accent : AppColors.sub,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border,
          ),
      ],
    );
  }
}

class _GoalSectionState extends State<_GoalSection> {
  bool _collapsed = false;

  Future<void> _handleToggleTask(AppState state, TaskViewItem task) async {
    try {
      final result = await state.toggleTaskByKey(task.key);
      if (!mounted) return;
      if (result.goalCompleted) {
        showToast(context, '目标已完成');
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
