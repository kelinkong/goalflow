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
    final goals = state.goals;

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
                    Text('目标', style: AppTextStyles.headline),
                    const SizedBox(height: 4),
                    Text('管理你的长期计划',
                        style: AppTextStyles.caption.copyWith(
                            fontStyle: FontStyle.italic, fontSize: 14)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _NewGoalButton(onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NewGoalScreen(),
                  ));
                }),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _GoalCard(
                    goal: goals[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
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

class _NewGoalButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewGoalButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text('新建目标',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final progress = state.getGoalProgress(goal);
    final progressPercent = state.getGoalProgressPercent(goal);
    final doneTasks = state.getGoalDoneTasks(goal);
    final totalTasks = state.getGoalTotalTasks(goal);
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
                    width: 44, height: 44,
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
                                fontSize: 16,
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
              GoalProgressBar(progress: progress),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$doneTasks/$totalTasks 任务',
                      style: AppTextStyles.caption),
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
