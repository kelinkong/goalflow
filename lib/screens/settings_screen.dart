import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../l10n/app_i18n.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getLifeDateRange(AppState state) {
    if (state.goals.isEmpty) return AppI18n.tr(zh: '这段时间', en: 'this period');
    final now = DateTime.now();
    final earliest = state.goals.fold<DateTime>(
      now,
      (prev, g) => g.createdAt.isBefore(prev) ? g.createdAt : prev,
    );
    final fmt = DateFormat(
      AppI18n.isEnglish ? 'yyyy.MM.dd' : 'yyyy.MM.dd',
      AppI18n.isEnglish ? 'en' : 'zh',
    );
    return '${fmt.format(earliest)} - ${fmt.format(now)}';
  }

  Future<void> _showProfileEditor(
    BuildContext context,
    AppState state,
  ) async {
    final nicknameCtrl = TextEditingController(text: state.userNickname ?? '');
    final picker = ImagePicker();
    final originalAvatar = state.userAvatar;
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
            maxWidth: 512, // 缩小尺寸
            maxHeight: 512,
          );
          if (file == null) return;

          final bytes = await file.readAsBytes();
          // 检查体积，如果原始体积超过 700KB，则提醒（虽然 512x512 50% 很难超过）
          if (bytes.length > 700 * 1024) {
            if (!sheetContext.mounted) return;
            showToast(sheetContext, sheetContext.tr(
              '图片体积过大，请选择更简单的图片',
              'Image is too large. Please choose a simpler one.',
            ));
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
            showToast(sheetContext, sheetContext.tr('昵称不能为空', 'Nickname cannot be empty.'));
            return;
          }
          setSheetState(() => isSaving = true);
          try {
            await state.updateProfile(
              nickname: nickname,
              avatar: draftAvatar == originalAvatar ? null : draftAvatar,
            );
            if (!sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            if (!context.mounted) return;
            showToast(context, context.tr('资料已更新', 'Profile updated.'));
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
                    Text(context.tr('编辑资料', 'Edit profile'), style: AppTextStyles.headline),
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
                                label: Text(context.tr('从相册选择', 'Choose from library')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionLabel(context.tr('昵称', 'Nickname')),
                    TextField(
                      controller: nicknameCtrl,
                      decoration: InputDecoration(
                        hintText: context.tr('起一个好听的名字', 'Choose a nice display name'),
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
                          isSaving ? context.tr('保存中...', 'Saving...') : context.tr('保存资料', 'Save profile'),
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
        : (state.userEmail ?? context.tr('游客', 'Guest'));

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
                    Text(context.tr('设置', 'Settings'), style: AppTextStyles.headline),
                    SizedBox(height: 4),
                    Text(
                      context.tr('个性化你的成长体验', 'Personalize your growth experience'),
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
                  displayName: state.isLoggedIn ? displayName : context.tr('未登录', 'Not signed in'),
                  subtitle: state.isLoggedIn
                      ? context.tr('开启成长同步中', 'Syncing your growth data')
                      : context.tr('本地存储 · 登录开启同步', 'Stored locally · Sign in to sync'),
                  avatar: state.userAvatar,
                  buttonLabel: state.isLoggedIn ? context.tr('退出', 'Sign out') : context.tr('登录', 'Sign in'),
                  onCardTap: state.isLoggedIn
                      ? () => _showProfileEditor(context, state)
                      : null,
                  onTap: () async {
                    if (state.isLoggedIn) {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(context.tr('退出登录', 'Sign out')),
                              content: Text(context.tr('退出后将无法实时同步成长数据，确认退出吗？',
                                  'You will stop syncing your data in real time after signing out. Continue?')),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(context.tr('取消', 'Cancel')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(context.tr('退出', 'Sign out')),
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
                  _Section(title: context.tr('提醒', 'Reminders'), rows: [
                    _Row(
                      label: context.tr('每日打卡提醒', 'Daily reminder'),
                      sub: state.reminderEnabled ? context.tr('已开启', 'On') : context.tr('已关闭', 'Off'),
                      toggle: true,
                      value: state.reminderEnabled,
                      onToggle: () async {
                        final wasEnabled = state.reminderEnabled;
                        final enabled = await context
                            .read<AppState>()
                            .setReminderEnabled(!wasEnabled);
                        if (!context.mounted) return;
                        if (!enabled && !wasEnabled) {
                          showToast(context, context.tr(
                            '还没有通知权限，所以暂时没法开启提醒',
                            'Notification permission is not available yet, so reminders cannot be turned on.',
                          ));
                          return;
                        }
                        showToast(
                          context,
                          wasEnabled ? context.tr('提醒已关闭', 'Reminder turned off.') : context.tr('提醒已开启', 'Reminder turned on.'),
                        );
                      },
                    ),
                    _Row(
                      label: context.tr('提醒时间', 'Reminder time'),
                      sub: state.reminderTimeLabel,
                      onTap: () async {
                        if (!state.reminderEnabled) {
                          showToast(context, context.tr(
                            '先把每日提醒打开，再设置时间',
                            'Turn on the daily reminder first, then choose a time.',
                          ));
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
                          context.tr('提醒时间已调整为 ${appState.reminderTimeLabel}',
                              'Reminder time updated to ${appState.reminderTimeLabel}.'),
                        );
                      },
                    ),
                    _Row(
                      label: context.tr('语言', 'Language'),
                      sub: state.locale.languageCode == 'en' ? 'English' : '简体中文',
                      onTap: () async {
                        final targetLocale = state.locale.languageCode == 'en'
                            ? const Locale('zh')
                            : const Locale('en');
                        await context.read<AppState>().setLocale(targetLocale);
                        if (!context.mounted) return;
                        showToast(
                          context,
                          targetLocale.languageCode == 'en'
                              ? 'Language switched to English.'
                              : '语言已切换为简体中文',
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _Section(title: context.tr('数据', 'Data'), rows: [
                    _Row(
                      label: context.tr('导出全部成长数据', 'Export all growth data'),
                      onTap: state.isLoggedIn
                          ? () async {
                              final exportJson = await state.exportGoalData();
                              if (!context.mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: Text(context.tr('导出全部成长数据', 'Export all growth data')),
                                  content: SizedBox(
                                    width: 520,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(context.tr(
                                            '包含你的目标、习惯记录和每日复盘。',
                                            'Includes your goals, habit records, and daily reviews.',
                                          )),
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
                                        child: Text(context.tr('关闭', 'Close'))),
                                    TextButton(
                                      onPressed: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: exportJson));
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        showToast(context, context.tr(
                                          '全部数据已经复制到剪贴板',
                                          'All data has been copied to the clipboard.',
                                        ));
                                      },
                                      child: Text(context.tr('复制', 'Copy')),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                    ),
                    _Row(
                      label: context.tr('清空历史数据', 'Clear history'),
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
                                      title: Text(context.tr('确定要清空这些记录吗？', 'Clear these records?')),
                                      content: Text(
                                          context.tr(
                                            '这会删除你从 $dateRange 以来留下的目标、习惯和复盘记录。\n\n删除后将无法恢复。',
                                            'This will delete the goals, habits, and reviews you have recorded since $dateRange.\n\nThis cannot be undone.',
                                          )),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(context.tr('先保留', 'Keep them'))),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(context.tr('确认清空', 'Clear now'),
                                              style: const TextStyle(
                                                  color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                              if (!confirmed) return;
                              await state.clearHistory();
                              if (!context.mounted) return;
                              showToast(context, context.tr('这些记录已经清空了', 'History cleared.'));
                            }
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _Section(title: context.tr('关于', 'About'), rows: [
                    _Row(label: context.tr('版本', 'Version'), sub: 'v1.0.0'),
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
