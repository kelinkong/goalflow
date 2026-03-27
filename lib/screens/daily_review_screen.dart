import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_review.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DailyReviewScreen extends StatefulWidget {
  final DateTime initialDate;

  const DailyReviewScreen({
    super.key,
    required this.initialDate,
  });

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  late DateTime _selectedDate;
  bool _loading = true;
  bool _hasExistingReview = false;
  String? _error;
  final _priorityCtrl = TextEditingController();
  final Map<DailyReviewDimension, TextEditingController> _commentCtrls = {
    for (final dimension in DailyReviewDimension.values)
      dimension: TextEditingController(),
  };
  final Map<DailyReviewDimension, DailyReviewStatus?> _statuses = {
    for (final dimension in DailyReviewDimension.values) dimension: null,
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReview());
  }

  @override
  void dispose() {
    _priorityCtrl.dispose();
    for (final controller in _commentCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      if (!appState.isDailyReviewMonthLoaded(_selectedDate)) {
        await appState.fetchDailyReviewCalendar(_selectedDate, silent: true);
      }
      final review =
          await appState.fetchDailyReview(_selectedDate, silent: true) ??
              DailyReview.empty(_selectedDate);
      _bindReview(review);
      if (!mounted) return;
      setState(() {
        _hasExistingReview = review.id != null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _bindReview(DailyReview review) {
    _priorityCtrl.text = review.tomorrowTopPriority;
    for (final item in review.items) {
      _statuses[item.dimension] = item.status;
      _commentCtrls[item.dimension]!.text = item.comment;
    }
  }

  Future<void> _save() async {
    for (final dimension in DailyReviewDimension.values) {
      if (_statuses[dimension] == null) {
        showToast(context, '${dimension.label} 还没有选择状态');
        return;
      }
      if (_commentCtrls[dimension]!.text.trim().isEmpty) {
        showToast(context, '${dimension.label} 的备注不能为空');
        return;
      }
    }
    if (_priorityCtrl.text.trim().isEmpty) {
      showToast(context, '明日最重要的事不能为空');
      return;
    }

    final review = DailyReview(
      date: _selectedDate,
      tomorrowTopPriority: _priorityCtrl.text.trim(),
      items: DailyReviewDimension.values
          .map((dimension) => DailyReviewItem(
                dimension: dimension,
                status: _statuses[dimension],
                comment: _commentCtrls[dimension]!.text.trim(),
              ))
          .toList(growable: false),
    );

    try {
      final saved = await context.read<AppState>().saveDailyReview(review);
      _bindReview(saved);
      if (!mounted) return;
      showToast(context, '每日复盘已保存');
      setState(() {
        _hasExistingReview = true;
      });
    } catch (e) {
      if (!mounted) return;
      showToast(context, userErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final saveActionKey = 'daily-review:save:${_dateKey(_selectedDate)}';
    final isSaving = state.isActionPending(saveActionKey);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_error != null)
                    SliverToBoxAdapter(child: _buildError())
                  else ...[
                    SliverToBoxAdapter(child: _buildDimensionList()),
                    SliverToBoxAdapter(child: _buildPriorityCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: _error != null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isSaving
                        ? '保存中...'
                        : (_hasExistingReview ? '保存复盘' : '开始复盘'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('每日复盘',
                    style: AppTextStyles.headline.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy年M月d日 EEEE', 'zh').format(_selectedDate),
                  style: AppTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('加载失败', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.body),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _loadReview,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: DailyReviewDimension.values
            .map((dimension) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildDimensionCard(dimension),
                ))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildDimensionCard(DailyReviewDimension dimension) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dimension.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: 0.5,
                ),
              ),
              _buildStatusSelector(dimension),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrls[dimension],
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.6),
            decoration: InputDecoration(
              hintText: '描述今天在${dimension.label}上的真实感受...',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(DailyReviewDimension dimension) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DailyReviewStatus.values.map((status) {
          final isSelected = _statuses[dimension] == status;
          return GestureDetector(
            onTap: () => setState(() => _statuses[dimension] = status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected 
                  ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                  : null,
              ),
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.4,
                child: Text(
                  _getStatusEmoji(status),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getStatusEmoji(DailyReviewStatus status) {
    switch (status) {
      case DailyReviewStatus.good: return '🌟';
      case DailyReviewStatus.normal: return '🙂';
      case DailyReviewStatus.bad: return '😐';
      default: return '？';
    }
  }

  Widget _buildPriorityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Text(
                '明日最重要的事', 
                style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _priorityCtrl,
            minLines: 1,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.6),
            decoration: InputDecoration(
              hintText: '只写一件最重要的事，开启新的一天...',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }
}
