import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import '../l10n/app_i18n.dart';
import '../theme.dart';

String userErrorMessage(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isEmpty) {
    return AppI18n.tr(
      zh: '操作失败，请稍后重试',
      en: 'Something went wrong. Please try again shortly.',
    );
  }
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
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
                      setState(
                          () {}); // Trigger rebuild to hide the clear button
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 0),
                      child: Icon(Icons.cancel, size: 18, color: AppColors.sub),
                    ),
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 24, maxHeight: 24),
          ),
          style: const TextStyle(
              fontSize: 15, color: AppColors.text, letterSpacing: 1),
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

class StatusGlyph extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size;
  final double iconSize;

  const StatusGlyph({
    super.key,
    required this.icon,
    this.active = false,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.accentLight,
          borderRadius: BorderRadius.circular(size * 0.33),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: active ? Colors.white : AppColors.text,
        ),
      );
}

class CheckGlyph extends StatelessWidget {
  final bool checked;
  final bool pending;
  final double size;
  final double iconSize;

  const CheckGlyph({
    super.key,
    required this.checked,
    this.pending = false,
    this.size = 22,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: checked ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: pending
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : checked
                ? Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: iconSize,
                  )
                : null,
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
                  child: CheckGlyph(
                    checked: widget.done,
                    pending: _togglePending,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      color: widget.done || widget.deferred
                          ? AppColors.sub
                          : AppColors.text,
                      decoration:
                          widget.done ? TextDecoration.lineThrough : null,
                      height: 1.45,
                    ),
                  ),
                ),
                if (widget.isMakeup)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(context.tr('补卡', 'Make-up'), style: AppTextStyles.caption),
                  ),
                if (widget.deferred) Text(context.tr('明日', 'Tomorrow'), style: AppTextStyles.caption),
                // Defer button (only for undone, non-deferred tasks)
                if (!widget.done &&
                    !widget.deferred &&
                    widget.onDefer != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _runDefer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                              context.tr('顺延', 'Defer'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.sub,
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
              height: 1,
              thickness: 1,
              color: AppColors.border,
              indent: 54,
              endIndent: 18,
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
          onPressed: widget.loading || _pending || widget.onTap == null
              ? null
              : _runTap,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.onTap != null ? AppColors.accent : AppColors.border,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: widget.loading || _pending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 8)
                    ],
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
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12)
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            message,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final labels = {
      'active': context.tr('进行中', 'Active'),
      'paused': context.tr('已暂停', 'Paused'),
      'done': context.tr('已完成', 'Done'),
      'completed': context.tr('已完成', 'Done'),
      'terminated': context.tr('已终止', 'Ended'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? AppColors.pill : AppColors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.accent : AppColors.sub,
        ),
      ),
    );
  }
}
