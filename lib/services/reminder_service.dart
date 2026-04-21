import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../l10n/app_i18n.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();
  static const int _dailyReminderId = 1001;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notifications.initialize(initializationSettings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final macPlugin = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
      final macGranted = await macPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
      return iosGranted && macGranted;
    }

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _dailyReminderId,
      AppI18n.tr(
        zh: 'GoalFlow 每日提醒',
        en: 'GoalFlow Daily Reminder',
      ),
      AppI18n.tr(
        zh: '如果你愿意，现在可以回来看看今天。',
        en: 'If you want, come back and check in with today.',
      ),
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'goalflow_daily_reminder',
          AppI18n.tr(zh: '每日提醒', en: 'Daily Reminder'),
          channelDescription: AppI18n.tr(
            zh: '轻提醒你回来看看今天的目标、习惯和记录',
            en: 'A gentle reminder to revisit today\'s goals, habits, and notes.',
          ),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await initialize();
    await _notifications.cancel(_dailyReminderId);
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }
  }
}
