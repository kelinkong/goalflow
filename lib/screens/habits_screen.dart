import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().fetchHabits(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final habits = state.habits.where((item) => item.isActive).toList();
    final today = DateTime.now();
    final doneCount = habits.where((item) => item.todayDone).length;

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
                          Text('习惯', style: AppTextStyles.headline),
                          const SizedBox(height: 4),
                          Text(
                            '你想成为什么样的人？',
                            style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openEditor(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10)
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 24, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _HabitSummaryCard(
                  total: habits.length,
                  done: doneCount,
                  bestStreak: habits.fold<int>(
                    0,
                    (best, habit) => best > state.habitStreak(habit)
                        ? best
                        : state.habitStreak(habit),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: habits.isEmpty
                    ? const _EmptyHabits()
                    : Column(
                        children: habits
                            .map((habit) => _HabitCard(
                                  habit: habit,
                                  onEdit: () =>
                                      _openEditor(context, habit: habit),
                                  onDelete: () => _deleteHabit(context, habit),
                                ))
                            .toList(growable: false),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Habit? habit}) async {
    await showHabitEditorSheet(context, habit: habit);
  }

  Future<void> _deleteHabit(BuildContext context, Habit habit) async {
    try {
      await context.read<AppState>().deleteHabit(habit.id);
      if (!context.mounted) return;
      showToast(context, '已删除习惯');
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }
}

Future<void> showHabitEditorSheet(BuildContext context, {Habit? habit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HabitEditorSheet(habit: habit),
  );
}

class _HabitSummaryCard extends StatelessWidget {
  final int total;
  final int done;
  final int bestStreak;

  const _HabitSummaryCard({
    required this.total,
    required this.done,
    required this.bestStreak,
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
          _MiniHabitStat(label: '今日完成', value: '$done'),
          const SizedBox(width: 10),
          _MiniHabitStat(label: '习惯总数', value: '$total'),
          const SizedBox(width: 10),
          _MiniHabitStat(label: '最长连续', value: '${bestStreak}天'),
        ],
      ),
    );
  }
}

class _MiniHabitStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniHabitStat({
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

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      await context.read<AppState>().toggleHabit(
                            habit,
                            DateTime.now(),
                          );
                      if (!context.mounted) return;
                      showToast(
                        context,
                        habit.todayDone ? '已取消今天的记录' : '已经为今天留下一次记录',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      showToast(context, userErrorMessage(e));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: habit.todayDone
                          ? AppColors.accent
                          : Colors.transparent,
                      border: Border.all(
                        color: habit.todayDone
                            ? AppColors.accent
                            : AppColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: habit.todayDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habit.category == null || habit.category!.isEmpty
                            ? '把想长期保留的行动，慢慢放进日常里'
                            : habit.category!,
                        style: AppTextStyles.caption.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        habit.todayDone ? AppColors.accentLight : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${habit.streak}天连续',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: habit.todayDone ? AppColors.accent : AppColors.sub,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border,
            indent: 18,
            endIndent: 18,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Row(
              children: [
                Text(
                  habit.todayDone ? '今天已经记下了' : '今天还没有留下记录',
                  style: AppTextStyles.caption.copyWith(
                    color: habit.todayDone ? AppColors.success : AppColors.sub,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEdit,
                  child: const Text('编辑'),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('删除'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitEditorSheet extends StatefulWidget {
  final Habit? habit;

  const _HabitEditorSheet({this.habit});

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.habit?.name ?? '');
    _categoryCtrl = TextEditingController(text: widget.habit?.category ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    if (name.isEmpty) {
      showToast(context, '习惯名称不能为空');
      return;
    }
    try {
      final appState = context.read<AppState>();
      if (_isEditing) {
        await appState.updateHabit(
          widget.habit!,
          name: name,
          category: category,
        );
      } else {
        await appState.addHabit(name: name, category: category);
      }
      if (!mounted) return;
      Navigator.pop(context);
      showToast(context, _isEditing ? '已保存习惯' : '已创建习惯');
    } catch (e) {
      if (!mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              _isEditing ? '编辑习惯' : '新建习惯',
              style: AppTextStyles.headline.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 18),
            const SectionLabel('名称'),
            FormInput(controller: _nameCtrl, hintText: '比如：每天阅读 20 分钟'),
            const SizedBox(height: 14),
            const SectionLabel('分类'),
            FormInput(controller: _categoryCtrl, hintText: '比如：健康 / 学习 / 社交'),
            const SizedBox(height: 20),
            AccentButton(
              label: _isEditing ? '保存习惯' : '创建习惯',
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            child: const Icon(Icons.self_improvement_rounded,
                color: AppColors.text),
          ),
          const SizedBox(height: 14),
          Text(
            '还没有习惯',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '先创建一个长期想坚持的行为，比如运动、阅读、早睡。',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
