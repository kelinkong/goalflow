import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/app_state.dart';
import '../services/ai_service.dart';
import '../widgets/common.dart';

class NewGoalScreen extends StatefulWidget {
  const NewGoalScreen({super.key});
  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> with SingleTickerProviderStateMixin {
  // step: form | loading | preview
  String _step = 'form';
  String _selectedEmoji = '🎯';
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _totalDays = 30;
  int _difficultyIndex = 0; // 0-3
  int _taskCountIndex = 0; // 0-2
  final Set<int> _restWeekdays = {}; // 1=Mon ... 7=Sun
  List<List<String>> _aiPlan = [];
  String? _error;
  final List<String> _logs = [];
  late final AnimationController _pulseCtrl;

  static const _emojis = ['🎯','📚','💪','🚀','🎨','💼','🌱','🏃','🎵','📝','💡','🔬'];
  static const _dayOptions = [7, 14, 30, 60, 90];
  static const _difficultyOptions = [
    ('轻松', '每天 5～10 分钟'),
    ('标准', '每天 15～30 分钟'),
    ('挑战', '每天 40～60 分钟'),
    ('高强度', '60 分钟以上'),
  ];
  static const _taskCountOptions = [
    ('少', '1～2 个/天'),
    ('中', '2～5 个/天'),
    ('多', '6～8 个/天'),
  ];
  static const _restOptions = [1, 2, 3, 4, 5, 6, 7];
  static const _weekdayLabels = ['周一','周二','周三','周四','周五','周六','周日'];

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
  }

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    setState(() { _logs.insert(0, '[$ts] $msg'); });
  }

  Future<void> _callAI() async {
    setState(() { _step = 'loading'; _error = null; });
    _addLog('开始调用 AI');
    _addLog('目标：${_nameCtrl.text.trim()} / ${_totalDays}天');
    final desc = _descCtrl.text.trim();
    _addLog(desc.isEmpty ? '补充说明：<空>' : '补充说明：$desc');
    _addLog('每日难度：${_difficultyOptions[_difficultyIndex].$1}');
    _addLog('每日任务数量：${_taskCountOptions[_taskCountIndex].$1}');
    if (_restWeekdays.isNotEmpty) {
      final labels = _restWeekdays.toList()..sort();
      _addLog('休息日：${labels.map((d) => _weekdayLabels[d - 1]).join('、')}');
    }
    try {
      final plan = await AIService.decomposeGoal(
        goalName: _nameCtrl.text,
        goalDesc: _descCtrl.text,
        totalDays: _totalDays,
        difficulty: _difficultyOptions[_difficultyIndex].$1,
        taskCount: _taskCountOptions[_taskCountIndex].$1,
        weeklyRestWeekdays: _restWeekdays.toList(),
        constraints: const [],
      );
      _addLog('AI 返回成功：${plan.length} 天计划');
      setState(() { _aiPlan = plan; _step = 'preview'; });
    } catch (e) {
      _addLog('AI 失败：${e.toString()}');
      setState(() { _error = 'AI 拆解失败：${e.toString()}'; _step = 'form'; });
    }
  }

  Future<void> _saveGoal() async {
    final goal = Goal(
      id: const Uuid().v4(),
      name: _nameCtrl.text,
      emoji: _selectedEmoji,
      desc: _descCtrl.text,
      totalDays: _totalDays,
      createdAt: DateTime.now(),
      taskTemplates: _aiPlan.isNotEmpty ? _aiPlan.first : const [],
      taskPlan: _aiPlan,
      difficulty: _difficultyOptions[_difficultyIndex].$1,
      taskCount: _taskCountOptions[_taskCountIndex].$1,
      weeklyRestWeekdays: _restWeekdays.toList(),
      constraints: const [],
    );
    await context.read<AppState>().addGoal(goal);
    if (mounted) {
      showToast(context, '目标已创建 🎉');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _buildBody()),
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(children: const [
                  Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                  SizedBox(width: 4),
                  Text('返回', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('新建目标',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.text, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('告诉 AI 你的目标，它来拆解每日任务',
                  style: TextStyle(fontSize: 14, color: AppColors.sub,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDEAEA)),
                ),
                child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
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
                    const Text('AI 调用日志',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sub)),
                    const SizedBox(height: 8),
                    ..._logs.take(6).map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(l, style: const TextStyle(fontSize: 12, color: AppColors.sub, height: 1.4)),
                    )),
                  ],
                ),
              ),
            ],

            const SectionLabel('选择图标'),
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _emojis.map((e) => GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _selectedEmoji == e ? AppColors.pill : AppColors.white,
                      border: Border.all(
                        color: _selectedEmoji == e ? AppColors.accent : AppColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 18))),
                  ),
                )).toList(),
              ),
            ),

            const SectionLabel('目标名称 *'),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '例如：备考英语四级',
                  hintStyle: TextStyle(color: AppColors.sub),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                style: const TextStyle(fontSize: 15, color: AppColors.text),
              ),
            ),

            const SectionLabel('每日难度'),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildChoiceRow<int>(
                    options: List.generate(
                      _difficultyOptions.length,
                      (i) => (i, _difficultyOptions[i].$1),
                    ),
                    value: _difficultyIndex,
                    onSelect: (v) => setState(() => _difficultyIndex = v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _difficultyOptions[_difficultyIndex].$2,
                    style: const TextStyle(fontSize: 12, color: AppColors.sub),
                  ),
                ],
              ),
            ),

            const SectionLabel('每日任务数量'),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildChoiceRow<int>(
                    options: List.generate(
                      _taskCountOptions.length,
                      (i) => (i, _taskCountOptions[i].$1),
                    ),
                    value: _taskCountIndex,
                    onSelect: (v) => setState(() => _taskCountIndex = v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _taskCountOptions[_taskCountIndex].$2,
                    style: const TextStyle(fontSize: 12, color: AppColors.sub),
                  ),
                ],
              ),
            ),

            // 额外限制已移除

            const SectionLabel('每周休息日（可选）'),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _restOptions.map((d) {
                  final active = _restWeekdays.contains(d);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (active) _restWeekdays.remove(d);
                      else _restWeekdays.add(d);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.pill : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? AppColors.accent : AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        _weekdayLabels[d - 1],
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? AppColors.accent : AppColors.sub,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SectionLabel('补充说明（可选）'),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '描述当前基础、期望结果，越详细 AI 拆解越精准…',
                  hintStyle: TextStyle(color: AppColors.sub, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.6),
              ),
            ),

            const SectionLabel('挑战周期'),
            Row(
              children: _dayOptions.map((d) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _totalDays = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: d == _dayOptions.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _totalDays == d ? AppColors.accent : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _totalDays == d ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text('${d}天',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _totalDays == d ? Colors.white : AppColors.sub,
                        ),
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 28),

            AccentButton(
              label: '让 AI 拆解每日任务',
              onTap: valid ? _callAI : null,
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
                ...List.generate(3, (i) => AnimatedBuilder(
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
                          color: AppColors.accent.withOpacity(opacity),
                        ),
                      ),
                    );
                  },
                )),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 22))),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('AI 拆解中…',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 10),
            Text('正在为「${_nameCtrl.text}」\n生成 $_totalDays 天每日任务计划',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.sub, height: 1.7)),
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
                    const Text('AI 调用日志',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sub)),
                    const SizedBox(height: 6),
                    ..._logs.take(4).map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(l, style: const TextStyle(fontSize: 12, color: AppColors.sub, height: 1.4)),
                    )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            ...['分析目标内容', '拆解每日任务', '生成执行计划'].asMap().entries.map((e) =>
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white, borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: AppColors.pill, shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent))),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value, style: const TextStyle(fontSize: 14, color: AppColors.sub)),
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
    final previewDays = _aiPlan.take(3).toList();
    final filters = <String>[];
    filters.add('难度：${_difficultyOptions[_difficultyIndex].$1}');
    filters.add('任务数：${_taskCountOptions[_taskCountIndex].$1}');
    if (_restWeekdays.isNotEmpty) {
      final labels = _restWeekdays.toList()..sort();
      filters.add('休息日：${labels.map((d) => _weekdayLabels[d - 1]).join('、')}');
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => setState(() => _step = 'form'),
                child: Row(children: const [
                  Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                  SizedBox(width: 4),
                  Text('重新填写', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_nameCtrl.text,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text)),
                  const SizedBox(height: 3),
                  Text('$_totalDays 天挑战', style: AppTextStyles.caption),
                ]),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('✦', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  const SizedBox(width: 6),
                  Text('AI 已生成 ${_aiPlan.length} 天计划',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ]),
              ),
              if (filters.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: filters.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(f, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                  )).toList(),
                ),
              ],
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const SectionLabel('任务预览'),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
              ),
              child: Column(
                children: previewDays.asMap().entries.map((e) {
                  final dayNum = e.key + 1;
                  final tasks = e.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.pill,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text('$dayNum', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('第 $dayNum 天', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                          ],
                        ),
                      ),
                      ...tasks.asMap().entries.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        child: Row(children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(t.value, style: const TextStyle(fontSize: 15, color: AppColors.text, height: 1.5))),
                        ]),
                      )),
                      if (e.key < (previewDays.length - 1))
                        Divider(height: 1, color: AppColors.border, indent: 52, endIndent: 18),
                    ],
                  );
                }).toList(),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 3, height: 34, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(child: Text('计划会覆盖 $_totalDays 天，并随天数循序渐进',
                    style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.65))),
              ]),
            ),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _callAI,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('重新生成', style: TextStyle(color: AppColors.sub, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('确认创建目标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ])),
        ),
      ],
    );
  }
}
