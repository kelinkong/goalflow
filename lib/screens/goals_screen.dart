import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'goal_detail_screen.dart';
import 'new_goal_screen.dart';
import 'templates_screen.dart';

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
                child: Row(
                  children: [
                    Expanded(
                      child: _NewGoalButton(
                        label: '新建目标',
                        accent: true,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const NewGoalScreen(),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NewGoalButton(
                        label: '模板库',
                        accent: false,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const TemplatesScreen(),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
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
  final String label;
  final bool accent;
  final VoidCallback onTap;
  const _NewGoalButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: accent ? AppColors.accent : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  accent ? Icons.add : Icons.dashboard_customize_rounded,
                  color: accent ? Colors.white : AppColors.accent,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: accent ? Colors.white : AppColors.accent,
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

  Future<void> _saveAsTemplate(BuildContext context) async {
    final tagsCtrl = TextEditingController();
    bool isPublic = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('保存为模板', style: AppTextStyles.headline),
                    const SizedBox(height: 8),
                    Text('模板会复用当前目标的逐日计划，适合稳定的可复制方案', style: AppTextStyles.caption),
                    const SizedBox(height: 16),
                    const SectionLabel('标签'),
                    FormInput(controller: tagsCtrl, hintText: '例如：英语,晨间,30天'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('提交公开模板审核', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                          Switch(
                            value: isPublic,
                            onChanged: (value) => setModalState(() => isPublic = value),
                            activeColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AccentButton(
                      label: '保存模板',
                      onTap: () async {
                        await context.read<AppState>().createTemplateFromGoal(
                              goal,
                              isPublic: isPublic,
                              tags: tagsCtrl.text,
                            );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        showToast(context, isPublic ? '模板已提交审核' : '模板已保存为私有模板');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    tagsCtrl.dispose();
  }

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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text)),
                        const SizedBox(height: 3),
                        Text('剩余 ${goal.remainingDays} 天',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _saveAsTemplate(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bookmark_add_outlined, size: 18, color: AppColors.sub),
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
