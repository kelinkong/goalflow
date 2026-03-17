import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../models/day_record.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

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
    final goal = state.goals.firstWhere((g) => g.id == widget.goalId);
    final progress = state.getGoalProgress(goal);
    final progressPercent = state.getGoalProgressPercent(goal);
    final doneTasks = state.getGoalDoneTasks(goal);
    final totalTasks = state.getGoalTotalTasks(goal);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, goal)),
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

  Widget _buildHeader(BuildContext context, Goal goal) {
    final state = context.watch<AppState>();
    final progress = state.getGoalProgress(goal);
    final progressPercent = state.getGoalProgressPercent(goal);
    final doneTasks = state.getGoalDoneTasks(goal);
    final totalTasks = state.getGoalTotalTasks(goal);
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
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: AppColors.text, letterSpacing: -0.5)),
                    const SizedBox(height: 3),
                    Text(goal.desc, style: AppTextStyles.caption),
                  ],
                ),
              ),
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
          GoalProgressBar(progress: progress, height: 6),
          const SizedBox(height: 8),
          Text('剩余 ${goal.remainingDays} 天', style: AppTextStyles.caption),

          // Action buttons
          if (!goal.isDone) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: goal.isPaused ? '恢复目标' : '暂停目标',
                    onTap: () async {
                      final newStatus = goal.isPaused ? 'active' : 'paused';
                      await context.read<AppState>()
                          .updateGoalStatus(goal.id, newStatus);
                      if (mounted) {
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
                        await context.read<AppState>().updateGoalStatus(goal.id, 'done');
                        if (mounted) Navigator.pop(context);
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

// ── Today Tab ────────────────────────────────────────────────────
class _TodayTab extends StatefulWidget {
  final Goal goal;
  const _TodayTab({required this.goal});

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  DayRecord? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final r = await state.getOrCreateRecord(widget.goal, DateTime.now());
    if (mounted) setState(() { _record = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    final record = _record!;
    final state = context.read<AppState>();

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
              children: record.tasks.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                return TaskCheckTile(
                  text: t.taskText,
                  done: t.isDone,
                  deferred: t.isDeferred,
                  isMakeup: t.isMakeup,
                  onToggle: () async {
                    if (t.isDone) {
                      await state.uncheck(widget.goal, DateTime.now(), i);
                    } else {
                      await state.checkIn(widget.goal, DateTime.now(), i);
                      if (mounted) showToast(context, '打卡成功 ✓');
                    }
                    await _load();
                  },
                  onDefer: t.isDone || t.isDeferred ? null : () async {
                    await state.deferTask(widget.goal, DateTime.now(), i);
                    if (mounted) showToast(context, '已顺延至明日');
                    await _load();
                  },
                  showDivider: i < record.tasks.length - 1,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _MiniCalendar(goal: widget.goal),
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
    final records = context.watch<AppState>().getRecordsForGoal(goal.id);
    final recordMap = {for (final r in records) r.id: r};

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
              final date = goal.createdAt.add(Duration(days: i));
              final id = DayRecord.makeId(goal.id, date);
              final record = recordMap[id];
              final isToday = dayNum == goal.todayDayNumber;
              final isFuture = dayNum > (goal.todayDayNumber ?? goal.totalDays);

              Color bg; Color fg; String label;
              if (isToday) { bg = AppColors.accent; fg = Colors.white; label = '今'; }
              else if (isFuture) { bg = Colors.transparent; fg = AppColors.sub; label = ''; }
              else if (record == null) { bg = AppColors.bg; fg = AppColors.sub; label = ''; }
              else if (record.allDone) { bg = AppColors.pill; fg = AppColors.accent; label = '✓'; }
              else { bg = const Color(0xFFFDEAEA); fg = AppColors.danger; label = '✗'; }

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

// ── Timeline Tab ─────────────────────────────────────────────────
class _TimelineTab extends StatelessWidget {
  final Goal goal;
  const _TimelineTab({required this.goal});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state.getRecordsForGoal(goal.id);
    final recordMap = {for (final r in records) r.dayNumber: r};
    final todayDayNum = goal.todayDayNumber ?? 0;

    // Show full cycle in ascending order
    final days = List.generate(goal.totalDays, (i) => i + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          // Start marker (top)
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Column(children: [
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border, width: 2, style: BorderStyle.solid),
                      shape: BoxShape.circle, color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('开始', style: AppTextStyles.caption),
                ]),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    DateFormat('yyyy年M月d日').format(goal.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            ],
          ),
          ...days.map((dayNum) {
            final isToday = dayNum == todayDayNum;
            final isFuture = todayDayNum == 0 ? true : dayNum > todayDayNum;
            final record = recordMap[dayNum];
            final date = goal.createdAt.add(Duration(days: dayNum - 1));
            final allDone = record?.allDone ?? false;

            return _TimelineDay(
              dayNum: dayNum,
              date: date,
              isToday: isToday,
              isFuture: isFuture,
              allDone: allDone,
              tasks: record != null
                  ? record.tasks
                  : goal.tasksForDayNumber(dayNum)
                      .map((t) => TaskRecord(taskText: t)).toList(),
              isLast: dayNum == goal.totalDays,
              onCheckIn: isToday ? (idx) async {
                final r = await state.getOrCreateRecord(goal, date);
                await state.checkIn(goal, date, idx);
                if (context.mounted) showToast(context, '打卡成功 ✓');
              } : null,
              onMakeup: (!isToday && !isFuture && record != null) ? (idx) async {
                await state.checkIn(goal, date, idx, isMakeup: true);
                if (context.mounted) showToast(context, '补卡成功 ✓');
              } : null,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineDay extends StatelessWidget {
  final int dayNum;
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool allDone;
  final List<TaskRecord> tasks;
  final bool isLast;
  final void Function(int)? onCheckIn;
  final void Function(int)? onMakeup;

  const _TimelineDay({
    required this.dayNum, required this.date,
    required this.isToday, required this.isFuture, required this.allDone,
    required this.tasks, required this.isLast,
    this.onCheckIn, this.onMakeup,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: node + line
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.accent
                        : allDone
                            ? AppColors.accentLight
                            : AppColors.white,
                    border: Border.all(
                      color: isToday || allDone ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isToday
                      ? Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                      : allDone
                          ? const Icon(Icons.check, size: 10, color: AppColors.accent)
                          : null,
                ),
                const SizedBox(height: 4),
                Text(
                  isToday ? '今天' : isFuture ? '第${dayNum}天（未到）' : '第${dayNum}天',
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday ? AppColors.accent : AppColors.sub,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 4)),
                  ),
              ],
            ),
          ),

          // Right: task card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday ? AppColors.accentLight : AppColors.border,
                  width: isToday ? 1.5 : 1,
                ),
                boxShadow: isToday
                    ? [BoxShadow(color: AppColors.accent.withOpacity(0.1), blurRadius: 16)]
                    : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isToday)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('TODAY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppColors.accent, letterSpacing: 0.8)),
                    ),
                  Text(DateFormat('M月d日').format(date), style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  ...tasks.asMap().entries.map((e) {
                    final i = e.key;
                    final t = e.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < tasks.length - 1 ? 8 : 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: t.isDone
                                ? null
                                : onCheckIn != null
                                    ? () => onCheckIn!(i)
                                    : onMakeup != null
                                        ? () => onMakeup!(i)
                                        : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                color: t.isDone ? AppColors.accent : Colors.transparent,
                                border: Border.all(
                                  color: t.isDone ? AppColors.accent : AppColors.border,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: t.isDone
                                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(t.taskText,
                              style: TextStyle(
                                fontSize: 13,
                                color: t.isDone ? AppColors.sub : AppColors.text,
                                decoration: t.isDone ? TextDecoration.lineThrough : null,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (t.isMakeup)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.pill,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('补卡',
                                  style: TextStyle(fontSize: 10, color: AppColors.accent)),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _ActionBtn({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => Material(
        color: danger ? const Color(0xFFFFF0F0) : AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: danger ? AppColors.danger : AppColors.sub)),
            ),
          ),
        ),
      );
}
