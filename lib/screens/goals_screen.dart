import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'goal_detail_screen.dart';
import 'new_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.goals.where((g) => g.isActive).toList();
    
    // 计算统计数据
    int totalTasks = 0;
    int doneTasks = 0;
    for (final g in goals) {
      totalTasks += state.goalTotalTaskCount(g);
      doneTasks += state.goalDoneTaskCount(g);
    }
    
    // 计算连击 (简化版，复用逻辑)
    int streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final date = DateTime(cursor.year, cursor.month, cursor.day);
      final tasks = goals.expand((g) => state.taskViewsForDate(g, date));
      if (!tasks.any((t) => t.done)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('目标', style: AppTextStyles.headline),
                          const SizedBox(height: 4),
                          Text('把大愿望拆解成小步子',
                              style: AppTextStyles.caption.copyWith(
                                  fontStyle: FontStyle.italic, fontSize: 14)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewGoalScreen()),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, size: 24, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _GoalSummaryCard(
                  doneTasks: doneTasks,
                  totalTasks: totalTasks,
                  streak: streak,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: goals.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyGoals())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _GoalCard(
                          goal: goals[i],
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GoalDetailScreen(goalId: goals[i].id),
                              )),
                        ),
                        childCount: goals.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  final int doneTasks;
  final int totalTasks;
  final int streak;

  const _GoalSummaryCard({
    required this.doneTasks,
    required this.totalTasks,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          _MiniGoalStat(label: '今日完成', value: '$doneTasks'),
          const SizedBox(width: 10),
          _MiniGoalStat(label: '任务总数', value: '$totalTasks'),
          const SizedBox(width: 10),
          _MiniGoalStat(label: '最长连续', value: '${streak}天'),
        ],
      ),
    );
  }
}

class _MiniGoalStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniGoalStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.pill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.track_changes_rounded, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有目标',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角创建一个目标，让 AI 帮你拆解成可执行的小任务。',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final progressPercent = state.goalProgressPercent(goal);
    final doneTasks = state.goalDoneTaskCount(goal);
    final totalTasks = state.goalTotalTaskCount(goal);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14)
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.pill,
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                      child: Text(goal.emoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      const SizedBox(height: 3),
                      Text('剩余 ${goal.remainingDays} 天',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                StatusBadge(goal.status),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppColors.sub, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            GoalProgressBar(progress: progressPercent / 100),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$doneTasks/$totalTasks 任务', style: AppTextStyles.caption),
                Text('${progressPercent}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
