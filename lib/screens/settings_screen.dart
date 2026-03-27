import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getLifeDateRange(AppState state) {
    if (state.goals.isEmpty) return '这段时间';
    final now = DateTime.now();
    final earliest = state.goals.fold<DateTime>(
      now,
      (prev, g) => g.createdAt.isBefore(prev) ? g.createdAt : prev,
    );
    final fmt = DateFormat('yyyy.MM.dd');
    return '${fmt.format(earliest)} - ${fmt.format(now)}';
  }

  Future<void> _showProfileEditor(
    BuildContext context,
    AppState state,
  ) async {
    final nicknameCtrl = TextEditingController(text: state.userNickname ?? '');
    final picker = ImagePicker();
    var draftAvatar = state.userAvatar;
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Future<void> pickAvatar(StateSetter setSheetState) async {
          final file = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 50, // 降低质量
            maxWidth: 512,    // 缩小尺寸
            maxHeight: 512,
          );
          if (file == null) return;
          
          final bytes = await file.readAsBytes();
          // 检查体积，如果原始体积超过 700KB，则提醒（虽然 512x512 50% 很难超过）
          if (bytes.length > 700 * 1024) {
            if (!sheetContext.mounted) return;
            showToast(sheetContext, '图片体积过大，请选择更简单的图片');
            return;
          }

          if (!sheetContext.mounted) return;
          setSheetState(() {
            draftAvatar = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          });
        }

        Future<void> saveProfile(StateSetter setSheetState) async {
          final nickname = nicknameCtrl.text.trim();
          if (nickname.isEmpty) {
            showToast(sheetContext, '昵称不能为空');
            return;
          }
          setSheetState(() => isSaving = true);
          try {
            await state.updateProfile(
              nickname: nickname,
              avatar: draftAvatar,
            );
            if (!sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            if (!context.mounted) return;
            showToast(context, '资料已更新');
          } catch (e) {
            if (!sheetContext.mounted) return;
            showToast(sheetContext, userErrorMessage(e));
          } finally {
            if (sheetContext.mounted) {
              setSheetState(() => isSaving = false);
            }
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('编辑资料', style: AppTextStyles.headline),
                    const SizedBox(height: 18),
                    Center(
                      child: Column(
                        children: [
                          _AvatarView(
                            avatar: draftAvatar,
                            size: 84,
                            borderRadius: 24,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            children: [
                              TextButton.icon(
                                onPressed: () => pickAvatar(setSheetState),
                                icon: const Icon(Icons.photo_library_rounded,
                                    size: 18),
                                label: const Text('从相册选择'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('昵称'),
                    TextField(
                      controller: nicknameCtrl,
                      decoration: InputDecoration(
                        hintText: '起一个好听的名字',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed:
                            isSaving ? null : () => saveProfile(setSheetState),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          isSaving ? '保存中...' : '保存资料',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final displayName = state.userNickname?.isNotEmpty == true
        ? state.userNickname!
        : (state.userEmail ?? '游客');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('设置', style: AppTextStyles.headline),
                    SizedBox(height: 4),
                    Text(
                      '个性化你的成长体验',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.sub,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _ProfileCard(
                  displayName: state.isLoggedIn ? displayName : '未登录',
                  subtitle: state.isLoggedIn ? '开启成长同步中' : '本地存储 · 登录开启同步',
                  avatar: state.userAvatar,
                  buttonLabel: state.isLoggedIn ? '退出' : '登录',
                  onCardTap: state.isLoggedIn
                      ? () => _showProfileEditor(context, state)
                      : null,
                  onTap: () async {
                    if (state.isLoggedIn) {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('退出登录'),
                              content: const Text('退出后将无法实时同步成长数据，确认退出吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('退出'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (confirmed) {
                        await state.logout();
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Section(title: '提醒', rows: [
                    _Row(
                      label: '每日打卡提醒',
                      sub: state.reminderEnabled ? '已开启' : '已关闭',
                      toggle: true,
                      value: state.reminderEnabled,
                      onToggle: () async {
                        final wasEnabled = state.reminderEnabled;
                        final enabled = await context
                            .read<AppState>()
                            .setReminderEnabled(!wasEnabled);
                        if (!context.mounted) return;
                        if (!enabled && !wasEnabled) {
                          showToast(context, '未获得通知权限，无法开启提醒');
                          return;
                        }
                        showToast(
                          context,
                          wasEnabled ? '已关闭提醒' : '已开启提醒',
                        );
                      },
                    ),
                    _Row(
                      label: '提醒时间',
                      sub: state.reminderTimeLabel,
                      onTap: () async {
                        if (!state.reminderEnabled) {
                          showToast(context, '先开启每日打卡提醒');
                          return;
                        }
                        final appState = context.read<AppState>();
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: state.reminderTime,
                        );
                        if (selected == null || !context.mounted) return;
                        await appState.setReminderTime(selected);
                        if (!context.mounted) return;
                        showToast(
                          context,
                          '提醒时间已更新为 ${appState.reminderTimeLabel}',
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _Section(title: '数据', rows: [
                    _Row(
                      label: '导出全部成长数据',
                      onTap: state.isLoggedIn
                          ? () async {
                              final exportJson = await state.exportGoalData();
                              if (!context.mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Text('导出全部成长数据'),
                                  content: SizedBox(
                                    width: 520,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('包含你的目标、习惯记录和每日复盘。'),
                                          const SizedBox(height: 16),
                                          SelectableText(exportJson,
                                              style: const TextStyle(
                                                  fontSize: 12, height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('关闭')),
                                    TextButton(
                                      onPressed: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: exportJson));
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        showToast(context, '全量数据已复制到剪贴板');
                                      },
                                      child: const Text('复制'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                    ),
                    _Row(
                      label: '清空历史数据',
                      danger: true,
                      onTap: state.isLoggedIn
                          ? () async {
                              final String dateRange = _getLifeDateRange(state);
                              final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      title: const Text('确定要清空吗？'),
                                      content: Text(
                                          '你要清空自己 $dateRange 的“人生”吗？\n\n此操作将永久删除所有目标、习惯和复盘记录，且无法找回。'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('再想想')),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('确定清空',
                                              style: TextStyle(
                                                  color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                              if (!confirmed) return;
                              await state.clearHistory();
                              if (!context.mounted) return;
                              showToast(context, '历史已归零，开启新篇章');
                            }
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const _Section(title: '关于', rows: [
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

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final String? avatar;
  final String buttonLabel;
  final VoidCallback? onCardTap;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.displayName,
    required this.subtitle,
    this.avatar,
    required this.buttonLabel,
    this.onCardTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _AvatarView(avatar: avatar, size: 54, borderRadius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          )),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.sub,
                            height: 1.4,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(buttonLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _AvatarView extends StatelessWidget {
  final String? avatar;
  final double size;
  final double borderRadius;

  const _AvatarView({
    required this.avatar,
    required this.size,
    required this.borderRadius,
  });

  ImageProvider<Object>? _avatarProvider() {
    final raw = avatar?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }

    final base64Data = raw.startsWith('data:image')
        ? raw.substring(raw.indexOf(',') + 1)
        : raw;
    try {
      return MemoryImage(base64Decode(base64Data));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _avatarProvider();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
        image: provider == null
            ? null
            : DecorationImage(
                image: provider,
                fit: BoxFit.cover,
              ),
      ),
      child: provider == null
          ? Icon(
              Icons.person_rounded,
              color: AppColors.text,
              size: size * 0.5,
            )
          : null,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: rows
                  .asMap()
                  .entries
                  .map((e) => Column(children: [
                        e.value,
                        if (e.key < rows.length - 1)
                          const Divider(
                            height: 1,
                            color: AppColors.border,
                            indent: 18,
                          ),
                      ]))
                  .toList(),
            ),
          ),
        ],
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String? sub;
  final bool toggle;
  final bool danger;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: danger ? AppColors.danger : AppColors.text,
                      )),
                  if (toggle && sub != null) ...[
                    const SizedBox(height: 4),
                    Text(sub!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.sub,
                        )),
                  ],
                ],
              ),
              if (toggle && value != null && onToggle != null)
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 26,
                    decoration: BoxDecoration(
                      color: value! ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment:
                          value! ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2)
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  onTap == null ? (sub ?? '') : '${sub ?? ''} ›',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
      );
}
