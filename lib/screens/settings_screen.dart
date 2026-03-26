import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remind = true;
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isLoggedIn) {
        state.fetchMedals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final displayName = state.userNickname?.isNotEmpty == true
        ? state.userNickname!
        : (state.userEmail ?? '已登录');
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('设置', style: AppTextStyles.headline),
                  const SizedBox(height: 4),
                  const Text('个性化你的体验',
                      style: TextStyle(fontSize: 14, color: AppColors.sub, fontStyle: FontStyle.italic)),
                ]),
              ),
            ),

            // Account card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('🧑', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(state.isLoggedIn ? displayName : '游客模式',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(state.isLoggedIn ? '云同步已开启' : '本地存储 · 登录开启云同步',
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ])),
                    GestureDetector(
                      onTap: () async {
                        if (state.isLoggedIn) {
                          await state.logout();
                        } else {
                          if (!context.mounted) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(state.isLoggedIn ? '退出' : '登录',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (state.isLoggedIn) ...[
                    _Section(title: '勋章', rows: [
                      if (state.medals.isEmpty)
                        const _Row(label: '还没有完成勋章', sub: '完成任意目标后自动发放')
                      else
                        ...state.medals.take(4).map((medal) => _Row(
                              label: '${medal.goalEmoji} ${medal.title}',
                              sub: DateFormat('yyyy.MM.dd').format(medal.awardedAt),
                            )),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  _Section(title: '通知', rows: [
                    _Row(label: '每日打卡提醒', toggle: true, value: _remind, onToggle: () => setState(() => _remind = !_remind)),
                    _Row(label: '提醒时间', sub: '19:00'),
                  ]),
                  const SizedBox(height: 20),
                  _Section(title: '外观', rows: [
                    _Row(label: '深色模式', toggle: true, value: _dark, onToggle: () => setState(() => _dark = !_dark)),
                  ]),
                  const SizedBox(height: 20),
                  _Section(title: '数据', rows: [
                    _Row(
                      label: '导出目标数据',
                      onTap: state.isLoggedIn ? () async {
                        final exportJson = await state.exportGoalData();
                        if (!context.mounted) return;
                        await showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('导出目标数据'),
                            content: SizedBox(
                              width: 520,
                              child: SingleChildScrollView(
                                child: SelectableText(exportJson, style: const TextStyle(fontSize: 12, height: 1.5)),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: exportJson));
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  showToast(context, '导出数据已复制到剪贴板');
                                },
                                child: const Text('复制'),
                              ),
                            ],
                          ),
                        );
                      } : null,
                    ),
                    _Row(
                      label: '清空历史数据',
                      danger: true,
                      onTap: state.isLoggedIn ? () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('清空历史数据'),
                            content: const Text('会删除你的目标、打卡记录、勋章和排行数据，但保留账号和模板。确认继续吗？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('确认清空', style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        ) ?? false;
                        if (!confirmed) return;
                        await state.clearHistory();
                        if (!context.mounted) return;
                        showToast(context, '历史数据已清空');
                      } : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _Section(title: '关于', rows: [
                    _Row(label: '版本', sub: 'v1.0.0'),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(title),
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          children: rows.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < rows.length - 1)
              Divider(height: 1, color: AppColors.border, indent: 18),
          ])).toList(),
        ),
      ),
    ],
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String? sub;
  final bool toggle, danger;
  final bool? value;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const _Row({
    required this.label,
    this.sub,
    this.toggle = false,
    this.danger = false,
    this.value,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: toggle ? null : onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                  color: danger ? AppColors.danger : AppColors.text)),
          if (toggle && value != null && onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 26,
                decoration: BoxDecoration(
                  color: value! ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value! ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                  ),
                ),
              ),
            )
          else
            Text('${sub ?? ''} ›', style: AppTextStyles.caption),
        ],
      ),
    ),
  );
}
