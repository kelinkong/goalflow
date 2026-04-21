import 'package:flutter/material.dart';
import '../l10n/app_i18n.dart';
import '../theme.dart';

Future<void> showCompletionCeremony(BuildContext context) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events,
                    size: 48, color: AppColors.accent),
                const SizedBox(height: 12),
                Text(context.tr('目标达成！', 'Goal completed!'),
                    style: AppTextStyles.headline),
                const SizedBox(height: 6),
                Text(context.tr('这一步已经完成了，先把这个时刻收下。',
                        'This step is done. Take a moment to keep it.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.sub)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  child: Text(context.tr('继续看看', 'Keep going'),
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
