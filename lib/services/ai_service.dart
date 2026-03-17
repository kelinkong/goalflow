import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get _baseUrl =>
      dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  static String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o';

  /// Ask AI to decompose a goal into a progressive day-by-day plan.
  /// Returns a list of tasks per day (length = totalDays).
  static Future<List<List<String>>> decomposeGoal({
    required String goalName,
    required String goalDesc,
    required int totalDays,
    String? difficulty,
    String? taskCount,
    List<int>? weeklyRestWeekdays,
    List<String>? constraints,
  }) async {
    final desc = goalDesc.trim();
    final minTasks = taskCount == '少' ? 1 : taskCount == '多' ? 6 : 2;
    final maxTasks = taskCount == '少' ? 2 : taskCount == '多' ? 8 : 5;
    final difficultyText = difficulty == null ? null
        : (difficulty == '轻松'
            ? '轻松（每天 5～10 分钟）'
            : difficulty == '标准'
                ? '标准（每天 15～30 分钟）'
                : difficulty == '挑战'
                    ? '挑战（每天 40～60 分钟）'
                    : '高强度（60 分钟以上）');
    final constraintText = (constraints != null && constraints.isNotEmpty)
        ? constraints.join('、')
        : null;
    final weekdayNames = const ['周一','周二','周三','周四','周五','周六','周日'];
    final restWeekdaysText = (weeklyRestWeekdays != null && weeklyRestWeekdays.isNotEmpty)
        ? weeklyRestWeekdays.map((d) => weekdayNames[(d - 1).clamp(0, 6)]).join('、')
        : null;
    final prompt = '''你是一个目标拆解助手。
用户设定了以下目标，请按「$totalDays 天」周期，生成循序渐进的每日任务计划。
要求：
1) 每天给出 $minTasks-$maxTasks 条任务，难度或量级随天数逐步递进；
2) 任务要具体、可量化、适合当天完成；
3) 必须覆盖全部 $totalDays 天。

目标名称：$goalName
补充说明：${desc.isEmpty ? '（未填写）' : desc}
周期天数：$totalDays 天
${difficultyText == null ? '' : '每日难度：$difficultyText'}
${restWeekdaysText == null ? '' : '休息日：$restWeekdaysText（休息日安排轻量复盘/整理，不要空白）'}
${constraintText == null ? '' : '额外限制：$constraintText'}

只返回 JSON 数组，不要有任何其他文字或 markdown。
格式如下（务必严格遵守）：
[
  {"day":1,"tasks":["任务1","任务2","任务3"]},
  {"day":2,"tasks":["任务1","任务2","任务3"]},
  ...
]''';

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 5000,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI request failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final raw = data['choices'][0]['message']['content'] as String;
    final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (_) {
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start >= 0 && end > start) {
        decoded = jsonDecode(cleaned.substring(start, end + 1));
      } else {
        rethrow;
      }
    }

    List<dynamic> days;
    if (decoded is Map && decoded['days'] is List) {
      days = decoded['days'] as List;
    } else if (decoded is List) {
      days = decoded;
    } else {
      throw Exception('AI response format invalid');
    }

    final plan = <List<String>>[];
    for (final item in days) {
      if (item is Map) {
        if (item['tasks'] is List) {
          final tasks = (item['tasks'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          plan.add(tasks);
        } else if (item['text'] != null) {
          plan.add([item['text'].toString()]);
        }
      } else if (item is List) {
        final tasks = item.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty).toList();
        plan.add(tasks);
      } else if (item is String) {
        plan.add([item]);
      }
    }

    // Normalize length to totalDays
    if (plan.isEmpty) {
      throw Exception('AI response empty');
    }
    if (plan.length >= totalDays) {
      return plan.take(totalDays).toList();
    }
    final last = plan.last;
    while (plan.length < totalDays) {
      plan.add(List<String>.from(last));
    }
    return plan;
  }
}
