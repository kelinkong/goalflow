import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ranking_entry.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TemplateRankingScreen extends StatefulWidget {
  final String templateId;
  final String templateName;

  const TemplateRankingScreen({
    super.key,
    required this.templateId,
    required this.templateName,
  });

  @override
  State<TemplateRankingScreen> createState() => _TemplateRankingScreenState();
}

class _TemplateRankingScreenState extends State<TemplateRankingScreen> {
  bool _loading = true;
  String? _error;
  List<RankingEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await context.read<AppState>().fetchRanking(widget.templateId);
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

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
                      child: Row(
                        children: const [
                          Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                          SizedBox(width: 4),
                          Text('返回', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('排行榜', style: AppTextStyles.headline),
                    const SizedBox(height: 4),
                    Text(widget.templateName, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _MessageCard(message: _error!)
                  else if (_entries.isEmpty)
                    const _MessageCard(message: '暂无排行数据')
                  else
                    ..._entries.map((entry) => _RankingCard(entry: entry)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final RankingEntry entry;

  const _RankingCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final changeLabel = entry.rankChange > 0
        ? '↑${entry.rankChange}'
        : (entry.rankChange < 0 ? '↓${entry.rankChange.abs()}' : '—');
    final changeColor = entry.rankChange > 0
        ? const Color(0xFF179D62)
        : (entry.rankChange < 0 ? AppColors.danger : AppColors.sub);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.rank <= 3 ? AppColors.pill : AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: entry.rank <= 3 ? AppColors.accent : AppColors.sub,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 5),
                GoalProgressBar(progress: entry.progressPercent / 100),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.progressPercent}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent),
              ),
              const SizedBox(height: 4),
              Text(
                changeLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: changeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message, style: AppTextStyles.caption),
    );
  }
}
