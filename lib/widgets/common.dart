import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import '../theme.dart';

String userErrorMessage(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isEmpty) return '操作失败，请稍后重试';
  return raw;
}

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

// ── Form Input Field ──────────────────────────────────────────────
class FormInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const FormInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<FormInput> createState() => _FormInputState();
}

class _FormInputState extends State<FormInput> {
  @override
  void initState() {
    super.initState();
    // Listen for changes to trigger rebuilds when controller text changes
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // Dispose listener when widget is removed
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Trigger rebuild when text changes
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: AppColors.sub),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            counterText: '', // Hide character counter
            suffixIcon: widget.controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      setState(() {}); // Trigger rebuild to hide the clear button
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 0),
                      child: Icon(Icons.cancel, size: 18, color: AppColors.sub),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 24, maxHeight: 24),
          ),
          style: const TextStyle(fontSize: 15, color: AppColors.text, letterSpacing: 1),
        ),
      ),
    );
  }
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
class TaskCheckTile extends StatefulWidget {
  final String text;
  final bool done;
  final bool deferred;
  final bool isMakeup;
  final FutureOr<void> Function() onToggle;
  final FutureOr<void> Function()? onDefer;
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
  State<TaskCheckTile> createState() => _TaskCheckTileState();
}

class _TaskCheckTileState extends State<TaskCheckTile> {
  bool _togglePending = false;
  bool _deferPending = false;

  Future<void> _runToggle() async {
    if (_togglePending || _deferPending) return;
    setState(() => _togglePending = true);
    try {
      await widget.onToggle();
    } finally {
      if (mounted) {
        setState(() => _togglePending = false);
      }
    }
  }

  Future<void> _runDefer() async {
    if (_deferPending || _togglePending || widget.onDefer == null) return;
    setState(() => _deferPending = true);
    try {
      await widget.onDefer!();
    } finally {
      if (mounted) {
        setState(() => _deferPending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: _runToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: widget.done ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: widget.done ? AppColors.accent : AppColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _togglePending
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : widget.done
                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      color: widget.done || widget.deferred ? AppColors.sub : AppColors.text,
                      decoration: widget.done ? TextDecoration.lineThrough : null,
                      height: 1.45,
                    ),
                  ),
                ),
                if (widget.isMakeup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('补卡', style: AppTextStyles.caption),
                  ),
                if (widget.deferred)
                  Text('明日', style: AppTextStyles.caption),
                // Defer button (only for undone, non-deferred tasks)
                if (!widget.done && !widget.deferred && widget.onDefer != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _runDefer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _deferPending
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.sub,
                              ),
                            )
                          : Text(
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
          if (widget.showDivider)
            Divider(
              height: 1, thickness: 1,
              color: AppColors.border,
              indent: 54, endIndent: 18,
            ),
        ],
      );
}

// ── Accent button ─────────────────────────────────────────────────
class AccentButton extends StatefulWidget {
  final String label;
  final FutureOr<void> Function()? onTap;
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
  State<AccentButton> createState() => _AccentButtonState();
}

class _AccentButtonState extends State<AccentButton> {
  bool _pending = false;

  Future<void> _runTap() async {
    if (_pending || widget.loading || widget.onTap == null) return;
    setState(() => _pending = true);
    try {
      await widget.onTap!();
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.loading || _pending || widget.onTap == null ? null : _runTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.onTap != null ? AppColors.accent : AppColors.border,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: widget.loading || _pending
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 8)],
                    Text(widget.label,
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
    'active': '进行中', 'paused': '已暂停', 'done': '已完成', 'completed': '已完成', 'terminated': '已终止',
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
