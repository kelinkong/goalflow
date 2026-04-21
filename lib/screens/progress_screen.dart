import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import '../l10n/app_i18n.dart';
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
        title: Text(context.tr('来到 GoalFlow 第 $days 天',
                'Day $days with GoalFlow'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
            context.tr(
              '你已经和 GoalFlow 一起走到第 $days 天。\n\n这些记录不是为了证明什么，而是在帮你看见自己是怎样一点点走过来的。\n\n有起伏也没关系，能继续回来看看，就很好。不要焦虑噢。',
              'You have made it to day $days with GoalFlow.\n\nThese records are not here to prove anything. They help you see how you have been moving forward bit by bit.\n\nUps and downs are normal. Coming back is already meaningful.',
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('知道了', 'Got it'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final trendPoints = _buildTrendPoints(goals, state);

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
                    Text(context.tr('轨迹', 'Progress'), style: AppTextStyles.headline),
                    const SizedBox(height: 4),
                    Text(context.tr('在这里，看见自己这段时间的变化',
                            'See how you have been changing over time here.'),
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
                      label: context.tr('记录天数', 'Days tracked'),
                      onTap: () => _showGrowthDialog(context, totalDays),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${reviewRate.round()}%',
                      label: context.tr('复盘覆盖', 'Review coverage'),
                      onTap: () => showToast(context, context.tr(
                        '点开下方日历格子，可以回看那天留下的记录。',
                        'Tap a calendar cell below to revisit the record from that day.',
                      )),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${habits.length}',
                      label: context.tr('塑造习惯', 'Active habits'),
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
                    _AlertCard(
                      insight: _buildTrajectoryInsight(
                        points: trendPoints,
                        streak: streak,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TrendChartCard(points: trendPoints, state: state),
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
          Text(context.tr('打卡日历', 'Check-in calendar'),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 16),
          Row(
            children: (context.isEnglish
                    ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    : ['日', '一', '二', '三', '四', '五', '六'])
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
              _CalendarLegendItem(color: _GitHubHeat.colors[0], label: context.tr('0项', '0')),
              _CalendarLegendItem(color: _GitHubHeat.colors[1], label: context.tr('1项', '1')),
              _CalendarLegendItem(color: _GitHubHeat.colors[2], label: context.tr('2项', '2')),
              _CalendarLegendItem(color: _GitHubHeat.colors[3], label: context.tr('3项', '3')),
            ],
          ),
          const SizedBox(height: 12),
          // 指标说明
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              context.tr(
                '● 左点：目标完成  ● 中点：习惯完成  ● 右点：复盘完成',
                '● Left: goals  ● Middle: habits  ● Right: review',
              ),
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
        color: completed ? Colors.white : AppColors.border,
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
                DateFormat(
                  context.isEnglish ? 'MMM d EEEE' : 'M月d日 EEEE',
                  context.isEnglish ? 'en' : 'zh',
                ).format(date),
                style: AppTextStyles.headline.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(value: '$doneCount', label: context.tr('已完成', 'Done')),
                  const SizedBox(width: 8),
                  _MiniStat(value: '$pendingCount', label: context.tr('待完成', 'Pending')),
                  const SizedBox(width: 8),
                  _MiniStat(value: '$deferredCount', label: context.tr('已顺延', 'Deferred')),
                ],
              ),
              const SizedBox(height: 18),
              SectionLabel(context.tr('任务完成情况', 'Task summary')),
              if (sections.isEmpty)
                _InfoCard(
                  child: Text(context.tr('这一天没有任务安排。', 'No tasks were scheduled for this day.'), style: AppTextStyles.body),
                )
              else
                ...sections.map((entry) => _TaskSummaryCard(
                      goal: entry.goal,
                      tasks: entry.tasks,
                    )),
              const SizedBox(height: 16),
              SectionLabel(context.tr('习惯打卡', 'Habit check-ins')),
              if (habits.isEmpty)
                _InfoCard(
                  child: Text(context.tr('这一天没有习惯记录。', 'No habit records for this day.'), style: AppTextStyles.body),
                )
              else
                _HabitSummaryCardInTimeline(habits: habits),
              const SizedBox(height: 16),
              SectionLabel(context.tr('每日复盘', 'Daily review')),
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
                ? context.tr('已完成', 'Done')
                : task.deferred
                    ? context.tr('已顺延', 'Deferred')
                    : context.tr('待完成', 'Pending');
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
            Text(context.tr('这一天还没有填写复盘。', 'No review has been written for this day yet.'), style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onOpen,
              child: Text(context.tr('去填写复盘', 'Write review')),
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
                          context.reviewDimensionLabel(item.dimension.apiValue),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sub,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item.status == null ? context.tr('未填写', 'Not set') : context.reviewStatusLabel(item.status!.apiValue)} · ${item.comment}',
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
              context.tr('明日最重要的事：${review!.tomorrowTopPriority}',
                  'Most important thing for tomorrow: ${review!.tomorrowTopPriority}'),
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
              child: Text(context.tr('查看 / 编辑复盘', 'View / Edit review')),
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
  final _TrajectoryInsight insight;
  const _AlertCard({required this.insight});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            )
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
                Text(context.tr('轨迹提示', 'Trajectory insight'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 5),
                Text(
                  insight.message,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.sub, height: 1.65),
                ),
              ])),
        ]),
      );
}

class _TrajectoryInsight {
  final String message;

  const _TrajectoryInsight({required this.message});
}

class _TrendPoint {
  final DateTime date;
  final int taskScore;
  final int habitScore;
  final int reviewScore;

  const _TrendPoint({
    required this.date,
    required this.taskScore,
    required this.habitScore,
    required this.reviewScore,
  });

  int get totalScore => taskScore + habitScore + reviewScore;

  bool get hasAnyScore => totalScore > 0;
}

class _TrendChartCard extends StatefulWidget {
  final List<_TrendPoint> points;
  final AppState state;

  const _TrendChartCard({
    required this.points,
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
      for (final goal in widget.state.goals) {
        unawaited(widget.state.fetchGoalTimeline(goal.id, silent: true));
      }

      // Fetch calendars for the 30-day chart window.
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      if (!widget.state.isHabitMonthLoaded(currentMonth)) {
        unawaited(widget.state.fetchHabitCalendar(currentMonth, silent: true));
      }
      if (!widget.state.isHabitMonthLoaded(previousMonth)) {
        unawaited(widget.state.fetchHabitCalendar(previousMonth, silent: true));
      }
      if (!widget.state.isDailyReviewMonthLoaded(currentMonth)) {
        unawaited(
            widget.state.fetchDailyReviewCalendar(currentMonth, silent: true));
      }
      if (!widget.state.isDailyReviewMonthLoaded(previousMonth)) {
        unawaited(
            widget.state.fetchDailyReviewCalendar(previousMonth, silent: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final hasAnyData = points.any((point) => point.hasAnyScore);
    final maxScore = _maxDailyScore(points);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('最近30天，你在往上走吗？', 'Are you trending upward over the last 30 days?'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              '完成 1 个任务 +5 分，完成 1 个习惯 +5 分，写复盘 +5 分。',
              'Each completed task is +5, each completed habit is +5, and each review is +5.',
            ),
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
                context.tr('先行动几天，这里才会长出你的趋势线。',
                    'Take action for a few days first, then your trend line will start to appear.'),
                style: AppTextStyles.caption.copyWith(fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  points: points,
                  maxScore: maxScore,
                ),
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
  final int maxScore;

  const _TrendChartPainter({
    required this.points,
    required this.maxScore,
  });

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
      final y = topPad + chartHeight * ratio;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        guidePaint,
      );
    }

    _drawScoreLine(
      canvas,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      leftPad: leftPad,
      topPad: topPad,
      values: points.map((point) => point.totalScore).toList(),
      maxScore: maxScore,
      color: AppColors.success,
    );
  }

  void _drawScoreLine(
    Canvas canvas, {
    required double chartWidth,
    required double chartHeight,
    required double leftPad,
    required double topPad,
    required List<int> values,
    required int maxScore,
    required Color color,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = color;
    Offset? previousPoint;
    for (var i = 0; i < values.length; i++) {
      final dx = leftPad + chartWidth * (i / (values.length - 1));
      final heightRatio = maxScore == 0 ? 0.0 : values[i] / maxScore;
      final dy =
          topPad + chartHeight - chartHeight * heightRatio.clamp(0.0, 1.0);
      final point = Offset(dx, dy);
      if (previousPoint != null) {
        canvas.drawLine(previousPoint, point, linePaint);
      }
      canvas.drawCircle(point, 1.9, dotPaint);
      previousPoint = point;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

List<_TrendPoint> _buildTrendPoints(List<Goal> goals, AppState state,
    {int days = 30}) {
  final today = DateTime.now();
  final points = List.generate(days, (index) {
    final date = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1 - index));

    final allTasks =
        goals.expand((goal) => state.taskViewsForDate(goal, date)).toList();
    final doneTasks = allTasks.where((task) => task.done).length;
    final totalHabits = state.doneHabitCountOn(date);
    final hasReview = state.hasReviewOn(date);

    return _TrendPoint(
      date: date,
      taskScore: doneTasks * 5,
      habitScore: totalHabits * 5,
      reviewScore: hasReview ? 5 : 0,
    );
  });
  return points;
}

_TrajectoryInsight _buildTrajectoryInsight({
  required List<_TrendPoint> points,
  required int streak,
}) {
  final recent = points.skip(math.max(0, points.length - 7)).toList();
  final previous = points.length > 7
      ? points.skip(math.max(0, points.length - 14)).take(7).toList()
      : const <_TrendPoint>[];
  final recentTotal = _averageScore(recent);
  final previousTotal = _averageScore(previous);
  final delta = recentTotal - previousTotal;
  final today = points.isEmpty ? null : points.last;
  final recentTask = _averageTaskScore(recent);
  final recentHabit = _averageHabitScore(recent);
  final recentReview = _averageReviewScore(recent);

  if (recentTotal == 0) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '轨迹还在积累数据，先按自己的节奏记录几天，再回来看看变化。',
        en: 'Your trajectory is still collecting data. Record a few days at your own pace, then come back to see the changes.',
      ),
    );
  }

  if (streak == 0 && recentTotal >= 12 && (today?.totalScore ?? 0) <= 5) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '前几天已经有一些积累了，今天补一个小动作，这条轨迹就会继续往前走。',
        en: 'You already built up something over the last few days. Add one small action today and the line keeps moving forward.',
      ),
    );
  }

  if (delta >= 4 && recentTotal >= 15) {
    return _TrajectoryInsight(
      message: streak >= 7
          ? AppI18n.tr(
              zh: '最近 7 天比前一周更稳定，连续 $streak 天的节奏对你是有帮助的。',
              en: 'The last 7 days were steadier than the week before. A $streak-day streak is clearly helping you.',
            )
          : AppI18n.tr(
              zh: '最近 7 天在回升，说明你已经找到一点适合自己的节奏了。',
              en: 'The last 7 days are improving, which means you are finding a rhythm that fits you.',
            ),
    );
  }

  if (recentHabit < recentTask && recentHabit <= recentReview) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '这段时间习惯完成度相对弱一些，先把最基础的一项稳下来就够了。',
        en: 'Habit consistency has been relatively weaker lately. Stabilize the most basic one first.',
      ),
    );
  }

  if (recentTask < recentHabit && recentTask <= recentReview) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '目标推进这一块可以再聚焦一点，先完成一个关键任务会更轻松。',
        en: 'Goal progress could be a bit more focused. Finishing one key task first will feel lighter.',
      ),
    );
  }

  if (recentReview <= 1 && recentTotal >= 10) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '这段时间行动不少，如果偶尔补一两次回看，会更容易看清自己的节奏。',
        en: 'You have taken quite a few actions lately. Adding an occasional review will help you see your rhythm more clearly.',
      ),
    );
  }

  if (streak >= 7 && recentTotal >= 15) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '你已经连续行动 $streak 天，最近的变化是在一点点累积出来的。',
        en: 'You have acted for $streak days in a row. The recent changes are being built little by little.',
      ),
    );
  }

  if (streak > 0) {
    return _TrajectoryInsight(
      message: AppI18n.tr(
        zh: '你已经连续行动 $streak 天，今天继续做一点，轨迹就会自然延续下去。',
        en: 'You have been moving for $streak straight days. Do a little more today and the trajectory will keep flowing.',
      ),
    );
  }

  return _TrajectoryInsight(
    message: AppI18n.tr(
      zh: '这几天有起伏很正常，先把今天过成“有记录的一天”就可以了。',
      en: 'Ups and downs over the last few days are normal. Start by making today a day with a record.',
    ),
  );
}

double _averageScore(List<_TrendPoint> points) {
  if (points.isEmpty) return 0;
  final total = points.fold<int>(0, (sum, point) => sum + point.totalScore);
  return total / points.length;
}

double _averageTaskScore(List<_TrendPoint> points) {
  if (points.isEmpty) return 0;
  final total = points.fold<int>(0, (sum, point) => sum + point.taskScore);
  return total / points.length;
}

double _averageHabitScore(List<_TrendPoint> points) {
  if (points.isEmpty) return 0;
  final total = points.fold<int>(0, (sum, point) => sum + point.habitScore);
  return total / points.length;
}

double _averageReviewScore(List<_TrendPoint> points) {
  if (points.isEmpty) return 0;
  final total = points.fold<int>(0, (sum, point) => sum + point.reviewScore);
  return total / points.length;
}

int _maxDailyScore(List<_TrendPoint> points) {
  final maxValue = points.fold<int>(
    0,
    (currentMax, point) => math.max(currentMax, point.totalScore),
  );
  return maxValue <= 0 ? 5 : maxValue;
}
