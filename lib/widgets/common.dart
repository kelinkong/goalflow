import 'package:flutter/material.dart';
import '../theme.dart';

// ── Section label ─────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label.toUpperCase(), style: AppTextStyles.label),
      );
}

// ── App card ──────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding ?? const EdgeInsets.all(18),
            child: child,
          ),
        ),
      );
}

// ── Checkbox tile ─────────────────────────────────────────────────
class TaskCheckTile extends StatelessWidget {
  final String text;
  final bool done;
  final bool deferred;
  final bool isMakeup;
  final VoidCallback onToggle;
  final VoidCallback? onDefer;
  final bool showDivider;
  final double fontSize;

  const TaskCheckTile({
    super.key,
    required this.text,
    required this.done,
    required this.deferred,
    required this.isMakeup,
    required this.onToggle,
    this.onDefer,
    this.showDivider = false,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: done ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: done ? AppColors.accent : AppColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: done || deferred ? AppColors.sub : AppColors.text,
                      decoration: done ? TextDecoration.lineThrough : null,
                      height: 1.45,
                    ),
                  ),
                ),
                if (isMakeup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('补卡', style: AppTextStyles.caption),
                  ),
                if (deferred)
                  Text('明日', style: AppTextStyles.caption),
                // Defer button (only for undone, non-deferred tasks)
                if (!done && !deferred && onDefer != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDefer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '顺延',
                        style: TextStyle(
                          fontSize: 12, color: AppColors.sub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1, thickness: 1,
              color: AppColors.border,
              indent: 54, endIndent: 18,
            ),
        ],
      );
}

// ── Accent button ─────────────────────────────────────────────────
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? leading;

  const AccentButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: onTap != null ? AppColors.accent : AppColors.border,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 8)],
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      );
}

// ── Progress bar ─────────────────────────────────────────────────
class GoalProgressBar extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final double height;

  const GoalProgressBar({super.key, required this.progress, this.height = 5});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: height,
          backgroundColor: AppColors.bg,
          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
        ),
      );
}

// ── Toast helper ─────────────────────────────────────────────────
void showToast(BuildContext context, String message) {
  final overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) return;

  final entry = OverlayEntry(
    builder: (_) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12)],
          ),
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), () {
    entry.remove();
  });
}

// ── Status badge ─────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  static const _labels = {
    'active': '进行中', 'paused': '已暂停', 'done': '已完成',
  };

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? AppColors.pill : AppColors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isActive ? AppColors.accent : AppColors.sub,
        ),
      ),
    );
  }
}
