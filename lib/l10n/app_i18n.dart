import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppI18n {
  static String currentLanguageCode = 'zh';

  static bool get isEnglish => currentLanguageCode == 'en';

  static String tr({
    required String zh,
    required String en,
  }) {
    return isEnglish ? en : zh;
  }
}

extension AppI18nContext on BuildContext {
  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';

  String tr(String zh, String en) => isEnglish ? en : zh;

  String formatMonthDay(DateTime date) {
    return DateFormat(
      isEnglish ? 'MMM d' : 'M月d日',
      isEnglish ? 'en' : 'zh',
    ).format(date);
  }

  String formatLongDate(DateTime date) {
    return DateFormat(
      isEnglish ? 'MMMM d, y' : 'yyyy年M月d日',
      isEnglish ? 'en' : 'zh',
    ).format(date);
  }

  String formatFullDate(DateTime date) {
    return DateFormat(
      isEnglish ? 'MMMM d, y EEEE' : 'yyyy年M月d日 EEEE',
      isEnglish ? 'en' : 'zh',
    ).format(date);
  }

  String formatShortWeekday(DateTime date) {
    return DateFormat(
      isEnglish ? 'EEE' : 'EEE',
      isEnglish ? 'en' : 'zh',
    ).format(date);
  }

  String weekdayChipLabel(int weekday) {
    const zh = ['一', '二', '三', '四', '五', '六', '日'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return isEnglish ? en[weekday - 1] : '周${zh[weekday - 1]}';
  }

  String goalStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return tr('进行中', 'Active');
      case 'paused':
        return tr('已暂停', 'Paused');
      case 'done':
      case 'completed':
        return tr('已完成', 'Done');
      case 'terminated':
        return tr('已终止', 'Ended');
      default:
        return status;
    }
  }

  String reviewDimensionLabel(String apiValue) {
    switch (apiValue) {
      case 'WORK_STUDY':
        return tr('工作/学业', 'Work / Study');
      case 'HEALTH':
        return tr('健康', 'Health');
      case 'RELATIONSHIP':
        return tr('人际关系', 'Relationships');
      case 'HOBBY':
        return tr('爱好', 'Hobbies');
      default:
        return apiValue;
    }
  }

  String reviewStatusLabel(String apiValue) {
    switch (apiValue) {
      case 'GOOD':
        return tr('好', 'Good');
      case 'NORMAL':
        return tr('一般', 'Okay');
      case 'BAD':
        return tr('差', 'Low');
      default:
        return apiValue;
    }
  }
}
