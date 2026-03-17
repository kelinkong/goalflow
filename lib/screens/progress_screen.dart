import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../models/day_record.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.goals;

    // Aggregate stats
    final allRecords = goals.expand((g) => state.getRecordsForGoal(g.id)).toList();
    final doneDays = allRecords.where((r) => r.allDone).length;
    final totalTasks = goals.fold<int>(0, (a, g) => a + state.getGoalTotalTasks(g));
    final doneTasks = goals.fold<int>(0, (a, g) => a + state.getGoalDoneTasks(g));
    final rate = totalTasks > 0 ? (doneTasks / totalTasks * 100).round() : 0;

    // Streak calculation (consecutive days with allDone up to today)
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      bool anyGoalDone = false;
      for (final g in goals) {
        final r = state.getRecord(g.id, date);
        if (r != null && r.allDone) { anyGoalDone = true; break; }
      }
      if (anyGoalDone) streak++;
      else if (i > 0) break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('进度', style: AppTextStyles.headline),
                  const SizedBox(height: 4),
                  Text(DateFormat('yyyy年M月').format(today),
                      style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic, fontSize: 14)),
                ]),
              ),
            ),

            // Stats row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _StatCard(value: '$doneTasks', label: '已完成', accent: false),
                    const SizedBox(width: 10),
                    _StatCard(value: '${streak}天', label: '连续打卡', accent: false),
                    const SizedBox(width: 10),
                    _StatCard(value: '$rate%', label: '完成率', accent: true),
                  ],
                ),
              ),
            ),

            // Calendar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _MonthCalendar(goals: goals, state: state),
              ),
            ),

            // Per-goal progress
            if (goals.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('目标进度'),
                      ...goals.map((g) => _GoalProgressRow(goal: g, state: state)),
                    ],
                  ),
                ),
              ),

            // Alert
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

class _StatCard extends StatelessWidget {
  final String value, label;
  final bool accent;
  const _StatCard({required this.value, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: accent ? AppColors.accent : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                    color: accent ? Colors.white : AppColors.text)),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(fontSize: 11,
                    color: accent ? Colors.white.withOpacity(0.6) : AppColors.sub)),
          ]),
        ),
      );
}

class _MonthCalendar extends StatelessWidget {
  final List<Goal> goals;
  final AppState state;
  const _MonthCalendar({required this.goals, required this.state});

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('打卡日历',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 16),
          Row(
            children: ['日','一','二','三','四','五','六']
                .map((d) => Expanded(
                  child: Center(child: Text(d,
                      style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final date = DateTime(now.year, now.month, day);
              final isToday = day == now.day;
              final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

              // Check if any goal has allDone record for this date
              bool anyDone = false, anyMiss = false;
              for (final g in goals) {
                final r = state.getRecord(g.id, date);
                if (r != null && r.allDone) anyDone = true;
                else if (r != null && !isFuture) anyMiss = true;
              }

              Color bg; Color fg; String label;
              if (isToday) { bg = AppColors.accent; fg = Colors.white; label = '$day'; }
              else if (isFuture) { bg = Colors.transparent; fg = AppColors.sub; label = '$day'; }
              else if (anyDone) { bg = AppColors.pill; fg = AppColors.accent; label = '✓'; }
              else if (anyMiss) { bg = const Color(0xFFFDEAEA); fg = AppColors.danger; label = '✗'; }
              else { bg = Colors.transparent; fg = AppColors.sub; label = '$day'; }

              return Container(
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg))),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Legend(color: AppColors.pill, textColor: AppColors.accent, symbol: '✓', label: '完成'),
            const SizedBox(width: 20),
            _Legend(color: const Color(0xFFFDEAEA), textColor: AppColors.danger, symbol: '✗', label: '未完成'),
          ]),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color, textColor;
  final String symbol, label;
  const _Legend({required this.color, required this.textColor, required this.symbol, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 18, height: 18,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      child: Center(child: Text(symbol, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w700))),
    ),
    const SizedBox(width: 6),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _GoalProgressRow extends StatelessWidget {
  final Goal goal;
  final AppState state;
  const _GoalProgressRow({required this.goal, required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.getGoalProgress(goal);
    final progressPercent = state.getGoalProgressPercent(goal);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(children: [
        Text(goal.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(goal.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 6),
          GoalProgressBar(progress: progress),
        ])),
        const SizedBox(width: 12),
        Text('$progressPercent%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
      ]),
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
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 3, height: 36, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('提醒', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 5),
        Text(
          streak == 0
              ? '今天还没有打卡，快去完成今日任务吧！'
              : streak >= 7
                  ? '太棒了！你已连续打卡 $streak 天，继续保持！🔥'
                  : '你已连续打卡 $streak 天，保持节奏！',
          style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.65),
        ),
      ])),
    ]),
  );
}
