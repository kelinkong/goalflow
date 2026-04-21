import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../l10n/app_i18n.dart';
import '../models/goal_decomposition.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

class NewGoalScreen extends StatefulWidget {
  final Goal? initialGoal;

  const NewGoalScreen({super.key, this.initialGoal});
  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen>
    with SingleTickerProviderStateMixin {
  // step: form | loading | preview
  String _step = 'form';
  String _selectedEmoji = '🎯';
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _totalDays = 30;
  int _taskCountIndex = 0; // 0-2
  List<List<String>> _aiPlan = [];
  List<GoalPhase> _phases = [];
  String? _error;
  final List<String> _logs = [];
  late final AnimationController _pulseCtrl;

  static const _emojis = [
    '🎯',
    '📚',
    '💪',
    '🚀',
    '🎨',
    '💼',
    '🌱',
    '🏃',
    '🎵',
    '📝',
    '💡',
    '🔬'
  ];
  static const _dayOptions = [7, 14, 30, 60, 90];
  bool get _isEditing => widget.initialGoal != null;

  List<(String, String)> _taskCountOptions(BuildContext context) => [
        (context.tr('少', 'Light'), context.tr('1～2 个/天', '1-2 / day')),
        (context.tr('中', 'Medium'), context.tr('2～5 个/天', '2-5 / day')),
        (context.tr('多', 'Heavy'), context.tr('6～8 个/天', '6-8 / day')),
      ];

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    final initialGoal = widget.initialGoal;
    if (initialGoal != null) {
      _step = 'preview';
      _selectedEmoji = initialGoal.emoji;
      _nameCtrl.text = initialGoal.name;
      _descCtrl.text = initialGoal.desc;
      _totalDays = initialGoal.totalDays;
      _aiPlan =
          initialGoal.taskPlan.map((day) => List<String>.from(day)).toList();
    }
  }

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$ts] $msg');
    });
  }

  Future<void> _callAI() async {
    setState(() {
      _step = 'loading';
      _error = null;
    });
    final taskCountOptions = _taskCountOptions(context);
    _addLog(context.tr('开始调用 AI', 'Calling AI'));
    _addLog(context.tr('目标：${_nameCtrl.text.trim()} / $_totalDays天',
        'Goal: ${_nameCtrl.text.trim()} / $_totalDays days'));
    final desc = _descCtrl.text.trim();
    _addLog(desc.isEmpty
        ? context.tr('当前基础：<空>', 'Current level: <empty>')
        : context.tr('当前基础：$desc', 'Current level: $desc'));
    _addLog(context.tr('每日任务数量：${taskCountOptions[_taskCountIndex].$1}',
        'Daily task load: ${taskCountOptions[_taskCountIndex].$1}'));
    try {
      final goalPreview = Goal(
        id: '',
        name: _nameCtrl.text,
        emoji: _selectedEmoji,
        desc: _descCtrl.text,
        totalDays: _totalDays,
        createdAt: DateTime.now(),
        taskTemplates: [],
        taskPlan: [],
      );
      final result = await context.read<AppState>().decompose(goalPreview);
      _addLog(context.tr(
          'AI 返回成功：${result.taskPlan.length} 天计划 / ${result.phases.length} 个阶段',
          'AI returned ${result.taskPlan.length} planned days / ${result.phases.length} phases'));
      setState(() {
        _aiPlan = result.taskPlan;
        _phases = result.phases;
        _step = 'preview';
      });
    } catch (e) {
      _addLog(context.tr('AI 失败：${e.toString()}', 'AI failed: ${e.toString()}'));
      setState(() {
        _error = userErrorMessage(e);
        _step = 'form';
      });
    }
  }

  Future<void> _saveGoal() async {
    final goal = Goal(
      id: widget.initialGoal?.id ?? '',
      name: _nameCtrl.text,
      emoji: _selectedEmoji,
      desc: _descCtrl.text,
      totalDays: _aiPlan.isNotEmpty ? _aiPlan.length : _totalDays,
      status: widget.initialGoal?.status ?? 'active',
      createdAt: widget.initialGoal?.createdAt ?? DateTime.now(),
      taskTemplates: _aiPlan.isNotEmpty ? _aiPlan.first : const [],
      taskPlan: _aiPlan,
      taskCount: _taskCountOptions(context)[_taskCountIndex].$1,
      constraints: const [],
    );
    final appState = context.read<AppState>();
    if (_isEditing) {
      await appState.saveGoalEdits(goal);
    } else {
      await appState.addGoal(goal);
    }
    if (!mounted) return;
    showToast(context, _isEditing
        ? context.tr('目标已更新', 'Goal updated')
        : context.tr('目标已创建 🎉', 'Goal created 🎉'));
    Navigator.pop(context);
  }

  Future<void> _editTask(int dayIndex, int taskIndex) async {
    final ctrl = TextEditingController(text: _aiPlan[dayIndex][taskIndex]);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('编辑任务', 'Edit task')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr('输入任务内容', 'Enter task content'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(context.tr('取消', 'Cancel'))),
          TextButton(
            onPressed: () {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              setState(() => _aiPlan[dayIndex][taskIndex] = value);
              Navigator.pop(context);
            },
            child: Text(context.tr('保存', 'Save')),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
  }

  Future<void> _addTask(int dayIndex) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('新增任务', 'Add task')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr('输入新的任务内容', 'Enter a new task'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(context.tr('取消', 'Cancel'))),
          TextButton(
            onPressed: () {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              setState(() => _aiPlan[dayIndex].add(value));
              Navigator.pop(context);
            },
            child: Text(context.tr('添加', 'Add')),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
  }

  void _removeTask(int dayIndex, int taskIndex) {
    if (_aiPlan[dayIndex].length <= 1) return;
    setState(() => _aiPlan[dayIndex].removeAt(taskIndex));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _step == 'preview' ? _buildPreviewBottomBar() : null,
    );
  }

  Widget _buildPreviewBottomBar() {
    final state = context.watch<AppState>();
    final saveActionKey =
        _isEditing ? 'goal:edit:${widget.initialGoal!.id}' : 'goal:create';
    final isSaving = state.isActionPending(saveActionKey);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : _callAI,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(context.tr('重新生成', 'Regenerate'),
                  style: const TextStyle(
                      color: AppColors.sub, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSaving ? null : _saveGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSaving ? AppColors.border : AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing
                          ? context.tr('保存修改', 'Save changes')
                          : context.tr('确认创建目标', 'Create goal'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_step == 'loading') return _buildLoading();
    if (_step == 'preview') return _buildPreview();
    return _buildForm();
  }

  Widget _buildChoiceRow<T>({
    required List<(T, String)> options,
    required T value,
    required ValueChanged<T> onSelect,
  }) {
    return Row(
      children: options.map((opt) {
        final v = opt.$1;
        final label = opt.$2;
        final active = v == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: opt == options.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? Colors.white : AppColors.sub,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Form ──────────────────────────────────────────────────────
  Widget _buildForm() {
    final valid = _nameCtrl.text.trim().isNotEmpty;
    final state = context.watch<AppState>();
    final isCreating = state.isActionPending('goal:create');
    final taskCountOptions = _taskCountOptions(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            margin: const EdgeInsets.only(bottom: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(children: [
                  Icon(Icons.arrow_back_ios_new,
                      size: 14, color: AppColors.sub),
                  SizedBox(width: 4),
                  Text(context.tr('返回', 'Back'),
                      style: const TextStyle(fontSize: 14, color: AppColors.sub)),
                ]),
              ),
              const SizedBox(height: 18),
              Text(_isEditing ? context.tr('编辑目标', 'Edit goal') : context.tr('新建目标', 'New goal'),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(_isEditing
                      ? context.tr('调整目标信息，必要时重新生成任务', 'Adjust the goal details and regenerate tasks when needed.')
                      : context.tr('告诉 AI 你的目标和当前基础，它来拆解每日任务', 'Tell AI your goal and your current level, and it will break it into daily tasks.'),
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.sub,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDEAEA)),
                ),
                child: Text(_error!,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.danger)),
              ),
            ],
            if (_logs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('AI 调用日志', 'AI logs'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sub)),
                    const SizedBox(height: 8),
                    ..._logs.take(6).map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(l,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.sub,
                                  height: 1.4)),
                        )),
                  ],
                ),
              ),
            ],
            SectionLabel(context.tr('选择图标', 'Choose an icon')),
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10)
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis
                    .map((e) => GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _selectedEmoji == e
                                  ? AppColors.pill
                                  : AppColors.white,
                              border: Border.all(
                                color: _selectedEmoji == e
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                        ))
                    .toList(),
              ),
            ),
            SectionLabel(context.tr('目标名称 *', 'Goal name *')),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                maxLength: 15,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: InputDecoration(
                  hintText: context.tr('例如：备考英语四级', 'Example: Pass CET-4'),
                  hintStyle: TextStyle(color: AppColors.sub),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                style: const TextStyle(fontSize: 15, color: AppColors.text),
              ),
            ),
            SectionLabel(context.tr('每日任务数量', 'Daily task load')),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  _buildChoiceRow<int>(
                    options: List.generate(
                      taskCountOptions.length,
                      (i) => (i, taskCountOptions[i].$1),
                    ),
                    value: _taskCountIndex,
                    onSelect: (v) => setState(() => _taskCountIndex = v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    taskCountOptions[_taskCountIndex].$2,
                    style: const TextStyle(fontSize: 12, color: AppColors.sub),
                  ),
                ],
              ),
            ),
            SectionLabel(context.tr('当前基础（可选）', 'Current level (optional)')),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.tr(
                    '例如：刚开始接触 / 已坚持一周 / 目前每天只能投入 15 分钟…',
                    'Example: Just started / Already kept it up for a week / Can only spend 15 minutes a day for now...',
                  ),
                  hintStyle: TextStyle(color: AppColors.sub, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.text, height: 1.6),
              ),
            ),
            SectionLabel(context.tr('挑战周期', 'Challenge length')),
            Row(
              children: _dayOptions
                  .map((d) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _totalDays = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(
                                right: d == _dayOptions.last ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _totalDays == d
                                  ? AppColors.accent
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _totalDays == d
                                    ? AppColors.accent
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                context.tr('$d天', '$d days'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _totalDays == d
                                      ? Colors.white
                                      : AppColors.sub,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            AccentButton(
              label: _isEditing
                  ? context.tr('重新生成任务计划', 'Regenerate task plan')
                  : context.tr('让 AI 拆解每日任务', 'Let AI create daily tasks'),
              onTap: valid && !isCreating ? _callAI : null,
              loading: false,
              leading: const Text('✦', style: TextStyle(color: Colors.white)),
            ),
          ])),
        ),
      ],
    );
  }

  // ── Loading ───────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(
                    3,
                    (i) => AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            final phase = (_pulseCtrl.value + i * 0.18) % 1.0;
                            final opacity = 0.06 + (0.10 * (1 - phase));
                            final scale = 1.0 + phase * 0.22;
                            final size = 70.0 - i * 16;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent
                                      .withValues(alpha: opacity),
                                ),
                              ),
                            );
                          },
                        )),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(_selectedEmoji,
                          style: const TextStyle(fontSize: 22))),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(context.tr('AI 拆解中…', 'AI is breaking it down...'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            const SizedBox(height: 10),
            Text(context.tr('正在为「${_nameCtrl.text}」\n生成 $_totalDays 天每日任务计划',
                    'Generating a $_totalDays-day task plan\nfor "${_nameCtrl.text}"'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.sub, height: 1.7)),
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('AI 调用日志', 'AI logs'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sub)),
                    const SizedBox(height: 6),
                    ..._logs.take(4).map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(l,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.sub,
                                  height: 1.4)),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            ...[
              context.tr('分析目标内容', 'Analyzing your goal'),
              context.tr('拆解每日任务', 'Breaking down daily tasks'),
              context.tr('生成执行计划', 'Generating execution plan'),
            ].asMap().entries.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                            color: AppColors.pill, shape: BoxShape.circle),
                        child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent))),
                      ),
                      const SizedBox(width: 12),
                      Text(e.value,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.sub)),
                    ]),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ── Preview ───────────────────────────────────────────────────
  Widget _buildPreview() {
    final filters = <String>[];
    final taskCountOptions = _taskCountOptions(context);
    filters.add(context.tr('任务数：${taskCountOptions[_taskCountIndex].$1}',
        'Task load: ${taskCountOptions[_taskCountIndex].$1}'));
    if (_descCtrl.text.trim().isNotEmpty) {
      filters.add(context.tr('基础：${_descCtrl.text.trim()}',
          'Level: ${_descCtrl.text.trim()}'));
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            margin: const EdgeInsets.only(bottom: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => setState(() => _step = 'form'),
                child: Row(children: [
                  Icon(Icons.arrow_back_ios_new,
                      size: 14, color: AppColors.sub),
                  SizedBox(width: 4),
                  Text(context.tr('重新填写', 'Back to form'),
                      style: const TextStyle(fontSize: 14, color: AppColors.sub)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: AppColors.pill,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                      child: Text(_selectedEmoji,
                          style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_nameCtrl.text,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text)),
                  const SizedBox(height: 3),
                  Text(context.tr('$_totalDays 天挑战', '$_totalDays-day challenge'),
                      style: AppTextStyles.caption),
                ]),
              ]),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.pill,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('✦',
                      style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  const SizedBox(width: 6),
                  Text(context.tr(
                      '${_isEditing ? '当前' : 'AI 已生成'} ${_aiPlan.length} 天计划',
                      '${_isEditing ? 'Current' : 'AI generated'} ${_aiPlan.length} planned days'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent)),
                ]),
              ),
              if (filters.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: filters
                      .map((f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(f,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.sub)),
                          ))
                      .toList(),
                ),
              ],
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            SectionLabel(context.tr('任务计划', 'Task plan')),
            if (_phases.isNotEmpty) ...[
              SectionLabel(context.tr('阶段计划', 'Phases')),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12)
                  ],
                ),
                child: Column(
                  children: _phases.asMap().entries.map((entry) {
                    final phase = entry.value;
                    return Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        border: entry.key == _phases.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.pill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    '${phase.title} · 第 ${phase.startDay}-${phase.endDay} 天',
                                    '${phase.title} · Days ${phase.startDay}-${phase.endDay}',
                                  ),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phase.focus,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.sub,
                                      height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            SectionLabel(context.tr('每日任务', 'Daily tasks')),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12)
                ],
              ),
              child: Column(
                children: _aiPlan.asMap().entries.map((e) {
                  final dayNum = e.key + 1;
                  final tasks = e.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.pill,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text('$dayNum',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.sub)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(context.tr('第 $dayNum 天', 'Day $dayNum'),
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.sub)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _addTask(e.key),
                              child: Text(context.tr('添加任务', 'Add task')),
                            ),
                          ],
                        ),
                      ),
                      ...tasks.asMap().entries.map((t) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            child: Row(children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.border, width: 1.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(t.value,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.text,
                                          height: 1.5))),
                              IconButton(
                                onPressed: () => _editTask(e.key, t.key),
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.sub),
                              ),
                              IconButton(
                                onPressed: tasks.length <= 1
                                    ? null
                                    : () => _removeTask(e.key, t.key),
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.danger),
                              ),
                            ]),
                          )),
                      if (e.key < (_aiPlan.length - 1))
                        const Divider(
                            height: 1,
                            color: AppColors.border,
                            indent: 52,
                            endIndent: 18),
                    ],
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6)
                ],
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 3,
                    height: 34,
                    decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(context.tr(
                        '计划会覆盖 $_totalDays 天，并随天数循序渐进',
                        'The plan covers $_totalDays days and ramps up gradually.'),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.sub, height: 1.65))),
              ]),
            ),
          ])),
        ),
      ],
    );
  }
}
