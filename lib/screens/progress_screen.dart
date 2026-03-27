import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/daily_review.dart';
import '../models/habit.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'daily_review_screen.dart';
import 'habits_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  void _showGrowthDialog(BuildContext context, int days) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('来到 GoalFlow 第 $days 天',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text(
            '感谢你选择与 GoalFlow 共同成长。\n\n每一天的记录，都是对未来最好的投资。期待见证你更多的精彩时刻。✨'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续努力',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _navigateToHabits(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HabitsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.goals;
    final habits = state.habits.where((item) => item.isActive).toList();

    // 1. 成长天数：从第一个目标创建到现在的总天数
    final int totalDays = _calculateTotalDays(state);

    // 2. 复盘深度：有复盘的天数占总成长天数的百分比
    final int reviewDays = _calculateReviewDays(state);
    final double reviewRate =
        totalDays <= 0 ? 0 : (reviewDays / totalDays) * 100;

    final int streak = _buildStreak(goals, state);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('轨迹', style: AppTextStyles.headline),
                    const SizedBox(height: 4),
                    Text('在这里，看见你的成长历程',
                        style: AppTextStyles.caption.copyWith(
                            fontStyle: FontStyle.italic, fontSize: 14)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _StatCard(
                      value: '$totalDays',
                      label: '成长天数',
                      onTap: () => _showGrowthDialog(context, totalDays),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${reviewRate.round()}%',
                      label: '复盘深度',
                      onTap: () => showToast(context, '点击下方日历中的橙色区域，回看那天的思考。'),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${habits.length}',
                      label: '塑造习惯',
                      onTap: () => _navigateToHabits(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child:
                    _MonthCalendar(goals: goals, habits: habits, state: state),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  children: [
                    _AlertCard(streak: streak),
                    const SizedBox(height: 14),
                    _TrendChartCard(goals: goals, state: state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _calculateTotalDays(AppState state) {
  if (state.userCreatedAt == null) return 0;
  final now = DateTime.now();
  // 归一化日期，只比较日期部分
  final start = DateTime(state.userCreatedAt!.year, state.userCreatedAt!.month,
      state.userCreatedAt!.day);
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(start).inDays + 1;
}

int _calculateReviewDays(AppState state) {
  return state.reviewedDatesCount;
}

int _buildStreak(List<Goal> goals, AppState state) {
  var streak = 0;
  var cursor = DateTime.now();
  while (true) {
    final date = DateTime(cursor.year, cursor.month, cursor.day);
    final tasks = goals.expand((g) => state.taskViewsForDate(g, date));
    final hasDone = tasks.any((t) => t.done);
    if (!hasDone) break;
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final VoidCallback? onTap;
  const _StatCard({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ],
            ),
            child: Column(children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text)),
              const SizedBox(height: 5),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.sub)),
            ]),
          ),
        ),
      );
}

class _MonthCalendar extends StatefulWidget {
  final List<Goal> goals;
  final List<Habit> habits;
  final AppState state;
  const _MonthCalendar({
    required this.goals,
    required this.habits,
    required this.state,
  });

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final month = DateTime(DateTime.now().year, DateTime.now().month, 1);
      if (!widget.state.isDailyReviewMonthLoaded(month)) {
        unawaited(widget.state.fetchDailyReviewCalendar(month, silent: true));
      }
      if (!widget.state.isHabitMonthLoaded(month)) {
        unawaited(widget.state.fetchHabitCalendar(month, silent: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('打卡日历',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 16),
          Row(
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.sub))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final date = DateTime(now.year, now.month, day);
              final isToday = day == now.day;

              // 1. 目标数据 (顶部 1/3)
              final allTasks = widget.goals
                  .expand((g) => widget.state.taskViewsForDate(g, date))
                  .toList();
              final doneCount = allTasks.where((t) => t.done).length;
              final goalFinished =
                  allTasks.isNotEmpty && doneCount == allTasks.length;

              // 2. 习惯数据 (中部 1/3)
              final habitDone = widget.state.doneHabitCountOn(date);
              final habitTotal = widget.state.totalHabitCountOn(date);
              final habitFinished = habitTotal > 0 && habitDone == habitTotal;

              // 3. 复盘数据
              final reviewFinished = widget.state.hasReviewOn(date);
              final completedCount = [
                goalFinished,
                habitFinished,
                reviewFinished,
              ].where((item) => item).length;
              final heatColor = _GitHubHeat.colors[completedCount];

              return GestureDetector(
                onTap: () => _openDayOverview(context, date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: heatColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: heatColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isToday
                        ? Border.all(color: AppColors.accent, width: 2)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // 背景层
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent,
                        ),
                      ),
                      // 内容层：日期号 + 3个指标
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 日期号
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: completedCount >= 2
                                    ? AppColors.white
                                    : AppColors.text,
                              ),
                            ),
                            // 3个指标点
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _IndicatorDot(
                                  completed: goalFinished,
                                  isDark: completedCount >= 2,
                                ),
                                const SizedBox(width: 2),
                                _IndicatorDot(
                                  completed: habitFinished,
                                  isDark: completedCount >= 2,
                                ),
                                const SizedBox(width: 2),
                                _IndicatorDot(
                                  completed: reviewFinished,
                                  isDark: completedCount >= 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // 热力值图例
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalendarLegendItem(color: _GitHubHeat.colors[0], label: '0项'),
              _CalendarLegendItem(color: _GitHubHeat.colors[1], label: '1项'),
              _CalendarLegendItem(color: _GitHubHeat.colors[2], label: '2项'),
              _CalendarLegendItem(color: _GitHubHeat.colors[3], label: '3项'),
            ],
          ),
          const SizedBox(height: 12),
          // 指标说明
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '● 左点：目标完成  ● 中点：习惯完成  ● 右点：复盘完成',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDayOverview(BuildContext context, DateTime date) async {
    DailyReview? review;
    try {
      review = await widget.state.fetchDailyReview(date, silent: true);
    } catch (_) {
      review = widget.state.getCachedDailyReview(date);
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayOverviewSheet(
        date: date,
        goals: widget.goals,
        state: widget.state,
        review: review,
        habits: widget.state.activeHabitsForDate(date),
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool completed;
  final bool isDark;

  const _IndicatorDot({
    required this.completed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: completed
            ? (isDark ? Colors.white : AppColors.accent)
            : (isDark ? Colors.white.withOpacity(0.3) : AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _GitHubHeat {
  static const colors = [
    AppColors.bg,
    Color(0xFFc6e48b),
    Color(0xFF7bc96f),
    Color(0xFF239a3b),
  ];
}

class _CalendarLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _CalendarLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.sub,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DayOverviewSheet extends StatelessWidget {
  final DateTime date;
  final List<Goal> goals;
  final List<Habit> habits;
  final AppState state;
  final DailyReview? review;

  const _DayOverviewSheet({
    required this.date,
    required this.goals,
    required this.habits,
    required this.state,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final sections = goals
        .map((goal) => (goal: goal, tasks: state.taskViewsForDate(goal, date)))
        .where((entry) => entry.tasks.isNotEmpty)
        .toList(growable: false);
    final allTasks =
        sections.expand((entry) => entry.tasks).toList(growable: false);
    final doneCount = allTasks.where((task) => task.done).length;
    final deferredCount =
        allTasks.where((task) => !task.done && task.deferred).length;
    final pendingCount =
        allTasks.where((task) => !task.done && !task.deferred).length;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                DateFormat('M月d日 EEEE', 'zh').format(date),
                style: AppTextStyles.headline.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(value: '$doneCount', label: '已完成'),
                  const SizedBox(width: 8),
                  _MiniStat(value: '$pendingCount', label: '待完成'),
                  const SizedBox(width: 8),
                  _MiniStat(value: '$deferredCount', label: '已顺延'),
                ],
              ),
              const SizedBox(height: 18),
              const SectionLabel('任务完成情况'),
              if (sections.isEmpty)
                const _InfoCard(
                  child: Text('这一天没有任务安排。', style: AppTextStyles.body),
                )
              else
                ...sections.map((entry) => _TaskSummaryCard(
                      goal: entry.goal,
                      tasks: entry.tasks,
                    )),
              const SizedBox(height: 16),
              const SectionLabel('习惯打卡'),
              if (habits.isEmpty)
                const _InfoCard(
                  child: Text('这一天没有习惯记录。', style: AppTextStyles.body),
                )
              else
                _HabitSummaryCardInTimeline(habits: habits),
              const SizedBox(height: 16),
              const SectionLabel('每日复盘'),
              _ReviewSummaryCard(
                review: review,
                onOpen: () async {
                  Navigator.pop(context);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyReviewScreen(initialDate: date),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  final Goal goal;
  final List<TaskViewItem> tasks;

  const _TaskSummaryCard({
    required this.goal,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${goal.emoji} ${goal.name}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          ...tasks.map((task) {
            final label = task.done
                ? '已完成'
                : task.deferred
                    ? '已顺延'
                    : '待完成';
            final color = task.done
                ? AppColors.success
                : task.deferred
                    ? AppColors.sub
                    : AppColors.text;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      task.done
                          ? Icons.check_circle_rounded
                          : task.deferred
                              ? Icons.redo_rounded
                              : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final DailyReview? review;
  final VoidCallback onOpen;

  const _ReviewSummaryCard({
    required this.review,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review == null) ...[
            const Text('这一天还没有填写复盘。', style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onOpen,
              child: const Text('去填写复盘'),
            ),
          ] else ...[
            ...review!.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          item.dimension.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sub,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item.status?.label ?? '未填写'} · ${item.comment}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 6),
            Text(
              '明日最重要的事：${review!.tomorrowTopPriority}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onOpen,
              child: const Text('查看 / 编辑复盘'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HabitSummaryCardInTimeline extends StatelessWidget {
  final List<Habit> habits;

  const _HabitSummaryCardInTimeline({required this.habits});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: habits.map((habit) {
          final done = habit.todayDone;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 16,
                  color: done ? AppColors.success : AppColors.sub,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
                Text(
                  done ? '已完成' : '未完成',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.success : AppColors.sub,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final int streak;
  const _AlertCard({required this.streak});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('轨迹提示',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 5),
                Text(
                  streak == 0
                      ? '轨迹刚开始，先完成今天的一小步。'
                      : streak >= 7
                          ? '你已经连续行动 $streak 天，轨迹正在慢慢成形。'
                          : '你已经连续行动 $streak 天，别让这条线断在今天。',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.sub, height: 1.65),
                ),
              ])),
        ]),
      );
}

class _TrendPoint {
  final DateTime date;
  final double? goalRate;
  final double? habitRate;
  final double? reviewRate;

  const _TrendPoint({
    required this.date,
    required this.goalRate,
    required this.habitRate,
    required this.reviewRate,
  });
}

class _TrendChartCard extends StatefulWidget {
  final List<Goal> goals;
  final AppState state;

  const _TrendChartCard({
    required this.goals,
    required this.state,
  });

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // Fetch habits list to ensure we have habit data
      unawaited(widget.state.fetchHabits(silent: true));
      
      // Fetch goal timelines for trend data
      for (final goal in widget.goals) {
        unawaited(widget.state.fetchGoalTimeline(goal.id, silent: true));
      }
      
      // Fetch habit calendar for trend data
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      if (!widget.state.isHabitMonthLoaded(currentMonth)) {
        unawaited(widget.state.fetchHabitCalendar(currentMonth, silent: true));
      }
      if (!widget.state.isHabitMonthLoaded(previousMonth)) {
        unawaited(widget.state.fetchHabitCalendar(previousMonth, silent: true));
      }
    });
  }

  List<_TrendPoint> _buildPoints() {
    final today = DateTime.now();
    return List.generate(30, (index) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 29 - index));

      final allTasks = widget.goals
          .expand((goal) => widget.state.taskViewsForDate(goal, date))
          .toList();
      final doneTasks = allTasks.where((task) => task.done).length;
      final goalScore =
          allTasks.isEmpty ? null : doneTasks / allTasks.length.toDouble();

      final totalHabits = widget.state.totalHabitCountOn(date);
      final doneHabits = widget.state.doneHabitCountOn(date);
      final habitScore =
          totalHabits == 0 ? null : doneHabits / totalHabits.toDouble();
      final reviewScore = widget.state.hasReviewOn(date) ? 1.0 : 0.0;

      return _TrendPoint(
        date: date,
        goalRate: goalScore,
        habitRate: habitScore,
        reviewRate: reviewScore,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final hasAnyData = points.any(
      (point) =>
          point.goalRate != null ||
          point.habitRate != null ||
          point.reviewRate != null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近30天，你在往上走吗？',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '黑线是目标，绿线是习惯，橙线是复盘（7天移动平均）。',
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (!hasAnyData)
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '先行动几天，这里才会长出你的趋势线。',
                style: AppTextStyles.caption.copyWith(fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _TrendChartPainter(points: points),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
                  child: Column(
                    children: [
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('M/d').format(points.first.date),
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            DateFormat('M/d').format(points[14].date),
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            DateFormat('M/d').format(points.last.date),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<_TrendPoint> points;

  const _TrendChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 10.0;
    const bottomPad = 28.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final guidePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = topPad + chartHeight * (1 - ratio);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        guidePaint,
      );
    }

    _drawLine(
      canvas,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      leftPad: leftPad,
      topPad: topPad,
      values: _movingAverage(points.map((point) => point.goalRate).toList()),
      color: AppColors.accent,
    );
    _drawLine(
      canvas,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      leftPad: leftPad,
      topPad: topPad,
      values: _movingAverage(points.map((point) => point.habitRate).toList()),
      color: AppColors.success,
    );
    _drawLine(
      canvas,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      leftPad: leftPad,
      topPad: topPad,
      values: _movingAverage(points.map((point) => point.reviewRate).toList()),
      color: const Color(0xFFff8c42),
    );
  }

  void _drawLine(
    Canvas canvas, {
    required double chartWidth,
    required double chartHeight,
    required double leftPad,
    required double topPad,
    required List<double?> values,
    required Color color,
  }) {
    final path = Path();
    final pointPaint = Paint()..color = color;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    var hasStarted = false;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        hasStarted = false;
        continue;
      }
      final dx = leftPad + chartWidth * (i / (values.length - 1));
      final dy = topPad + chartHeight * (1 - value.clamp(0.0, 1.0));
      if (!hasStarted) {
        path.moveTo(dx, dy);
        hasStarted = true;
      } else {
        path.lineTo(dx, dy);
      }
      canvas.drawCircle(Offset(dx, dy), 1.4, pointPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  List<double?> _movingAverage(List<double?> values, [int window = 7]) {
    final n = values.length;
    final result = List<double?>.filled(n, null);
    for (var i = 0; i < n; i++) {
      var sum = 0.0;
      var count = 0;
      final start = math.max(0, i - window + 1);
      for (var j = start; j <= i; j++) {
        final value = values[j];
        if (value == null) continue;
        sum += value;
        count++;
      }
      if (count > 0) result[i] = sum / count;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
