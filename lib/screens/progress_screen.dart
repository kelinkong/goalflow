import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/daily_review.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'daily_review_screen.dart';
import 'template_ranking_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.goals;

    final int doneTasks =
        goals.fold<int>(0, (a, g) => a + state.goalDoneTaskCount(g));
    final int totalTasks =
        goals.fold<int>(0, (a, g) => a + state.goalTotalTaskCount(g));
    final rate = totalTasks > 0 ? (doneTasks / totalTasks * 100).round() : 0;
    final int streak = _buildStreak(goals, state);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('进度', style: AppTextStyles.headline),
                          const SizedBox(height: 4),
                          Text(DateFormat('yyyy年M月').format(DateTime.now()),
                              style: AppTextStyles.caption.copyWith(
                                  fontStyle: FontStyle.italic, fontSize: 14)),
                        ]),
                    GestureDetector(
                      onTap: () => state.shareProgress(context, streak: streak),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.pill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.share_outlined,
                                size: 16, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              '一键分享',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _StatCard(value: '$doneTasks', label: '已完成', accent: false),
                    const SizedBox(width: 10),
                    _StatCard(
                        value: '${streak}天', label: '连续打卡', accent: false),
                    const SizedBox(width: 10),
                    _StatCard(value: '$rate%', label: '完成率', accent: true),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _RankingSection(goals: goals, state: state),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _MonthCalendar(goals: goals, state: state),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _AlertCard(streak: streak),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  final bool accent;
  const _StatCard(
      {required this.value, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: accent ? AppColors.accent : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
            ],
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: accent ? Colors.white : AppColors.text)),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: accent
                        ? Colors.white.withOpacity(0.6)
                        : AppColors.sub)),
          ]),
        ),
      );
}

class _MonthCalendar extends StatefulWidget {
  final List<Goal> goals;
  final AppState state;
  const _MonthCalendar({required this.goals, required this.state});

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
              final allTasks = widget.goals
                  .expand((g) => widget.state.taskViewsForDate(g, date))
                  .toList();
              final doneCount = allTasks.where((t) => t.done).length;
              final hasTasks = allTasks.isNotEmpty;
              final allDone = hasTasks && doneCount == allTasks.length;
              final anyDone = doneCount > 0;
              final hasReview = widget.state.hasReviewOn(date);

              Color bg = Colors.transparent;
              Color fg = AppColors.sub;
              if (allDone) {
                bg = AppColors.accent;
                fg = Colors.white;
              } else if (anyDone) {
                bg = AppColors.pill;
                fg = AppColors.accent;
              }

              return GestureDetector(
                onTap: () => _openDayOverview(context, date),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !allDone
                        ? Border.all(color: AppColors.accent, width: 1.2)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text('$day',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: fg)),
                      ),
                      if (hasReview)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: allDone ? Colors.white : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CalendarLegendDot(color: AppColors.accent, label: '任务全部完成'),
              const SizedBox(width: 12),
              _CalendarLegendDot(color: AppColors.pill, label: '任务部分完成'),
              const SizedBox(width: 12),
              _CalendarLegendDot(color: AppColors.text, label: '已复盘'),
            ],
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
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _CalendarLegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.sub),
        ),
      ],
    );
  }
}

class _DayOverviewSheet extends StatelessWidget {
  final DateTime date;
  final List<Goal> goals;
  final AppState state;
  final DailyReview? review;

  const _DayOverviewSheet({
    required this.date,
    required this.goals,
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
              const SectionLabel('打卡情况'),
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

class _RankingSection extends StatelessWidget {
  final List<Goal> goals;
  final AppState state;
  const _RankingSection({required this.goals, required this.state});

  @override
  Widget build(BuildContext context) {
    final rankingGoals = goals
        .where((goal) => goal.templateId != null && goal.joinRanking)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('排行榜'),
        if (rankingGoals.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ],
            ),
            child: const Text(
              '你还没有加入任何模板排行榜，可在模板库使用模板时打开“加入排行榜”。',
              style: TextStyle(fontSize: 13, color: AppColors.sub, height: 1.6),
            ),
          )
        else
          ...rankingGoals
              .map((goal) => _RankingGoalRow(goal: goal, state: state)),
      ],
    );
  }
}

class _RankingGoalRow extends StatelessWidget {
  final Goal goal;
  final AppState state;

  const _RankingGoalRow({
    required this.goal,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final progress = state.goalProgressPercent(goal);
    final ranking = goal.templateId == null
        ? null
        : state.currentUserRankingEntry(goal.templateId!);
    final rankLabel = ranking == null ? '未上榜' : '#${ranking.rank}';
    final rankChange = ranking?.rankChange ?? 0;
    final arrow = rankChange > 0
        ? '↑$rankChange'
        : (rankChange < 0 ? '↓${rankChange.abs()}' : '—');
    final arrowColor = rankChange > 0
        ? const Color(0xFF179D62)
        : (rankChange < 0 ? AppColors.danger : AppColors.sub);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateRankingScreen(
              templateId: goal.templateId!,
              templateName: goal.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.pill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 16)),
                  Text(
                    rankLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  GoalProgressBar(progress: progress / 100),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$progress%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  arrow,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: arrowColor),
                ),
                const SizedBox(height: 2),
                const Text('查看榜单 ›',
                    style: TextStyle(fontSize: 11, color: AppColors.sub)),
              ],
            ),
          ],
        ),
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
                const Text('提醒',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 5),
                Text(
                  streak == 0
                      ? '今天还没有打卡，快去完成今日任务吧！'
                      : streak >= 7
                          ? '太棒了！你已连续打卡 $streak 天，继续保持！🔥'
                          : '你已连续打卡 $streak 天，保持节奏！',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.sub, height: 1.65),
                ),
              ])),
        ]),
      );
}
