import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal_template.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'template_detail_screen.dart';
import 'login_screen.dart';
import 'template_ranking_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isLoggedIn) {
        state.fetchTemplates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                      SizedBox(width: 4),
                      Text('返回', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
	                const Text('模板库', style: AppTextStyles.headline),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('登录后可浏览公开模板、加入排行榜并保存自己的模板',
                          style: TextStyle(fontSize: 14, color: AppColors.text, height: 1.6)),
                      const SizedBox(height: 16),
                      AccentButton(
                        label: '去登录',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final templates = _tab == 0 ? state.publicTemplates : state.myTemplates;
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                          SizedBox(width: 4),
                          Text('返回', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('模板库', style: AppTextStyles.headline),
                    const SizedBox(height: 4),
                    const Text('复用成熟计划，必要时加入同模板排行', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _TabChip(
                      label: '公开模板',
                      active: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _TabChip(
                      label: '我的模板',
                      active: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (templates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tab == 0 ? '还没有公开模板' : '还没有自己的模板，可在目标页把现有目标保存为模板',
                        style: AppTextStyles.caption,
                      ),
                    )
                  else
                    ...templates.map((template) => _TemplateCard(
                          template: template,
                          isMine: _tab == 1,
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : AppColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final GoalTemplate template;
  final bool isMine;

  const _TemplateCard({
    required this.template,
    required this.isMine,
  });

  Future<void> _showUseDialog(BuildContext context) async {
    if (template.isPending) {
      showToast(context, '审核中的模板暂不能创建目标');
      return;
    }

    bool joinRanking = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text(template.description, style: AppTextStyles.caption),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('加入排行榜', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('按完成任务数 / 总任务数参与同模板排名', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Switch(
                          value: joinRanking,
                          onChanged: (value) => setModalState(() => joinRanking = value),
                          activeThumbColor: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AccentButton(
                    label: '使用模板创建目标',
                    onTap: () async {
                      try {
                        await context.read<AppState>().useTemplate(
                              template.id,
                              joinRanking: joinRanking,
                            );
                      } catch (e) {
                        if (!context.mounted) return;
                        showToast(context, userErrorMessage(e));
                        return;
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      showToast(context, '已从模板创建目标');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final canViewRanking = state.hasJoinedRanking(template.id);
    final alreadyUsed = state.hasUsedTemplate(template.id);
    final canUseTemplate = !template.isPending;
    final canSubmitReview = isMine && !template.isPublic && !template.isPending;
    final showPendingPill = isMine && template.isPending;
    final showRejectedPill = isMine && template.isRejected;
    final showPublicPill = isMine && template.isPublic;
    final showDraftPill = isMine && template.isPrivateDraft;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateDetailScreen(template: template),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                      const SizedBox(height: 4),
                      Text(
                        '${template.totalDays} 天 · ${template.totalTasks} 个任务'
                        '${template.ownerNickname.isNotEmpty ? ' · ${template.ownerNickname}' : ''}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (isMine)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showPendingPill)
                        const _TemplateStatusPill(label: '审核中', color: AppColors.sub, bgColor: AppColors.bg),
                      if (showRejectedPill)
                        const _TemplateStatusPill(label: '未通过', color: AppColors.danger, bgColor: Color(0xFFFFF0F0)),
                      if (showPublicPill)
                        const _TemplateStatusPill(label: '公开', color: Color(0xFF179D62), bgColor: Color(0xFFEFFAF4)),
                      if (showDraftPill)
                        const _TemplateStatusPill(label: '私有', color: AppColors.sub, bgColor: AppColors.bg),
                      if (canSubmitReview) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            await context.read<AppState>().publishTemplate(template.id);
                            if (!context.mounted) return;
                            showToast(context, '模板已提交审核');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.pill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '发布模板',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            if (template.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(template.description, style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.6)),
            ],
            if (template.tagList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: template.tagList.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tag, style: AppTextStyles.caption),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '点击卡片查看模板内容',
              style: TextStyle(fontSize: 12, color: AppColors.sub),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AccentButton(
                    label: template.isPending ? '审核中不可用' : alreadyUsed ? '已使用' : '使用模板',
                    onTap: (!canUseTemplate || alreadyUsed) ? null : () => _showUseDialog(context),
                  ),
                ),
                if (canViewRanking) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemplateRankingScreen(
                              templateId: template.id,
                              templateName: template.name,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('排行榜'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _TemplateStatusPill({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
