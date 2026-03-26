import 'package:flutter/material.dart';

import '../models/goal_template.dart';
import '../theme.dart';

class TemplateDetailScreen extends StatelessWidget {
  final GoalTemplate template;

  const TemplateDetailScreen({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
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
                    Text(template.name, style: AppTextStyles.headline),
                    const SizedBox(height: 6),
                    Text(
                      '${template.totalDays} 天 · ${template.totalTasks} 个任务'
                      '${template.ownerNickname.isNotEmpty ? ' · ${template.ownerNickname}' : ''}',
                      style: AppTextStyles.caption,
                    ),
                    if (template.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          template.description,
                          style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.7),
                        ),
                      ),
                    ],
                    if (template.tagList.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: template.tagList.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(tag, style: AppTextStyles.caption),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tasks = index < template.taskPlan.length ? template.taskPlan[index] : const <String>[];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '第 ${index + 1} 天',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (tasks.isEmpty)
                            const Text('当天暂无任务', style: AppTextStyles.caption)
                          else
                            ...tasks.asMap().entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: entry.key == tasks.length - 1 ? 0 : 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      margin: const EdgeInsets.only(top: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.pill,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.text,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                  childCount: template.totalDays,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
