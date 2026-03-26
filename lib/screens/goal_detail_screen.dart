import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/completion_ceremony.dart';
import 'new_goal_screen.dart';
import 'template_ranking_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  int _tab = 0; // 0=today 1=timeline

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matches = state.goals.where((g) => g.id == widget.goalId);
    final goal = matches.isEmpty ? null : matches.first;
    if (goal == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.maybePop(context);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, state, goal)),
            SliverToBoxAdapter(child: _buildTabSwitch()),
            if (_tab == 0)
              SliverToBoxAdapter(child: _TodayTab(goal: goal))
            else
              SliverToBoxAdapter(child: _TimelineTab(goal: goal)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state, Goal goal) {
    final progressPercent = state.goalProgressPercent(goal);
    final doneTasks = state.goalDoneTaskCount(goal);
    final totalTasks = state.goalTotalTaskCount(goal);

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                SizedBox(width: 4),
                Text('返回', style: TextStyle(fontSize: 14, color: AppColors.sub)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                    color: AppColors.pill,
                    borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(goal.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            color: AppColors.text, letterSpacing: -0.5)),
                    const SizedBox(height: 3),
                    Text(goal.desc, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (goal.templateId == null && !goal.isDone) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewGoalScreen(initialGoal: goal),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.pill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('编辑', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  ),
                ),
              ],
              StatusBadge(goal.status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$doneTasks/$totalTasks 任务',
                  style: AppTextStyles.caption),
              Text('${progressPercent}%',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 8),
          GoalProgressBar(progress: progressPercent / 100, height: 6),
          const SizedBox(height: 8),
          Text('剩余 ${goal.remainingDays} 天', style: AppTextStyles.caption),
          if (!goal.isDone) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (goal.templateId != null && goal.joinRanking) ...[
                  Expanded(
                    child: _ActionBtn(
                      label: '模板排行',
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
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _ActionBtn(
                    label: goal.isPaused ? '恢复目标' : '暂停目标',
                    onTap: () async {
                      final newStatus = goal.isPaused ? 'active' : 'paused';
                      final ok = await context.read<AppState>()
                          .updateGoalStatus(goal.id, newStatus);
                      if (mounted && ok) {
                        showToast(context, newStatus == 'active' ? '目标已恢复' : '目标已暂停');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: '终止目标',
                    danger: true,
                    onTap: () async {
                      final ok = await _confirmEnd(context);
                      if (ok && mounted) {
                        final updated = await context.read<AppState>().updateGoalStatus(goal.id, 'terminated');
                        if (mounted && updated) Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSwitch() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Row(
          children: ['今日任务', '全部时间轴'].asMap().entries.map((e) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == e.key ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _tab == e.key ? FontWeight.w700 : FontWeight.w400,
                    color: _tab == e.key ? Colors.white : AppColors.sub,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      );

  Future<bool> _confirmEnd(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('终止目标', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('终止后将保留历史记录，但不可恢复。确认终止吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('终止', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _TodayTab extends StatelessWidget {
  final Goal goal;
  const _TodayTab({required this.goal});

  Future<void> _handleToggleTask(
    BuildContext context,
    AppState state,
    TaskViewItem task,
  ) async {
    String fallbackToast = task.done ? '已取消完成' : '已完成任务';
    try {
      final result = await state.toggleTaskByKey(task.key);
      if (!context.mounted) return;
      if (result.goalCompleted) {
        showToast(context, '目标已完成，已获得勋章');
        showCompletionCeremony(context);
      } else {
        showToast(context, fallbackToast);
      }
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }

  Future<void> _handleDeferTask(
    BuildContext context,
    AppState state,
    TaskViewItem task,
  ) async {
    showToast(context, '已顺延任务');
    try {
      await state.deferTaskByKey(task.key, DateTime.now());
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tasks = state.taskViewsForDate(goal, DateTime.now());
    if (tasks.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('今天没有任务')));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('今日任务'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
            ),
            child: Column(
              children: tasks.asMap().entries.map<Widget>((e) {
                final task = e.value;
                return TaskCheckTile(
                  text: task.text,
                  done: task.done,
                  deferred: task.deferred,
                  isMakeup: task.isMakeup,
                  onToggle: () => _handleToggleTask(context, state, task),
                  onDefer: !task.done ? () => _handleDeferTask(context, state, task) : null,
                  showDivider: e.key < tasks.length - 1,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _MiniCalendar(goal: goal),
        ],
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  final Goal goal;
  const _MiniCalendar({required this.goal});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('打卡记录'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10, mainAxisSpacing: 5, crossAxisSpacing: 5,
            ),
            itemCount: goal.totalDays,
            itemBuilder: (context, i) {
              final dayNum = i + 1;
              final date = goal.dateForDay(dayNum);
              final tasks = state.taskViewsForDate(goal, date);
              final allDone = tasks.isNotEmpty && tasks.every((t) => t.done);
              final anyDone = tasks.any((t) => t.done);
              final isToday = dayNum == goal.todayDayNumber;
              Color bg = AppColors.bg;
              Color fg = AppColors.sub;
              String label = '';
              if (allDone) {
                bg = AppColors.accent;
                fg = Colors.white;
                label = '✓';
              } else if (anyDone) {
                bg = AppColors.pill;
                fg = AppColors.accent;
                label = '•';
              } else if (isToday) {
                bg = AppColors.accent;
                fg = Colors.white;
                label = '今';
              }

              return Container(
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(7)),
                child: Center(child: Text(label,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg))),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final Goal goal;
  const _TimelineTab({required this.goal});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final timelineDays = state.timelineForGoal(goal);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        children: timelineDays.map((day) {
          final dayNum = day.dayNumber;
          final date = day.date;
          final tasks = day.tasks;
          final doneCount = tasks.where((t) => t.done).length;
          final dateText = DateFormat('MM-dd').format(date);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Day $dayNum · $dateText',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const Spacer(),
                    Text('$doneCount/${tasks.length}', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  const Text('无任务', style: TextStyle(fontSize: 12, color: AppColors.sub))
                else
                  ...tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${task.done ? '✓' : task.deferred ? '↷' : '○'} ${task.text}',
                          style: TextStyle(
                            fontSize: 12,
                            color: task.done ? AppColors.sub : AppColors.text,
                            decoration: task.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final FutureOr<void> Function() onTap;
  final bool danger;
  const _ActionBtn({required this.label, required this.onTap, this.danger = false});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pending = false;

  Future<void> _runTap() async {
    if (_pending) return;
    setState(() => _pending = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        color: widget.danger ? const Color(0xFFFFF0F0) : AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _pending ? null : _runTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: _pending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.danger ? AppColors.danger : AppColors.sub,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.danger ? AppColors.danger : AppColors.sub,
                      ),
                    ),
            ),
          ),
      ),
    );
}
