import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/goal_decomposition.dart';

class ApiService {
  final String baseUrl =
      dotenv.get('API_BASE_URL', fallback: 'http://localhost:8081');
  String? _token;
  VoidCallback? onUnauthorized;

  void setToken(String token) {
    _token = token.isEmpty ? null : token;
  }

  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    } catch (_) {}
    return '请求失败 (${response.statusCode})';
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required String action,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await request().timeout(timeout);
    } on SocketException {
      throw Exception('网络连接失败，请检查网络后重试');
    } on TimeoutException {
      throw Exception('$action超时，请稍后重试');
    } on http.ClientException {
      throw Exception('网络请求失败，请稍后重试');
    } on FormatException {
      throw Exception('服务器返回异常，请稍后重试');
    }
  }

  Never _throwFriendlyError(http.Response response, {required String action}) {
    final rawMessage = _parseErrorMessage(response);
    final status = response.statusCode;

    if (status == 401) {
      if (action != '登录' && action != '注册') {
        onUnauthorized?.call();
      }
      if (action == '登录') {
        throw Exception('邮箱或密码不正确');
      }
      throw Exception('登录状态已过期，请重新登录');
    }

    if (status == 403) {
      if (rawMessage.contains('登录状态已过期')) {
        if (action != '登录' && action != '注册') {
          onUnauthorized?.call();
        }
        throw Exception('登录状态已过期，请重新登录');
      }
      if (rawMessage.isNotEmpty && rawMessage != '请求失败 ($status)') {
        throw Exception(rawMessage);
      }
      throw Exception('$action失败，当前无权限');
    }

    if (status == 404) {
      throw Exception('$action失败，内容不存在或已被删除');
    }

    if (status == 408 || status == 504) {
      throw Exception('$action超时，请稍后重试');
    }

    if (status >= 500) {
      if (action == 'AI 拆解' || rawMessage.contains('AI decomposition failed')) {
        throw Exception('AI 拆解失败，请稍后重试');
      }
      throw Exception('$action失败，服务器暂时不可用');
    }

    if (rawMessage.isNotEmpty && rawMessage != '请求失败 ($status)') {
      throw Exception(rawMessage);
    }

    throw Exception('$action失败，请稍后重试');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
      action: '登录',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('登录失败：Token 缺失');
      }
      return {'token': token};
    } else {
      _throwFriendlyError(response, action: '登录');
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String nickname) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'nickname': nickname,
        }),
      ),
      action: '注册',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        return {'token': token};
      }
      return {'message': response.body};
    } else {
      _throwFriendlyError(response, action: '注册');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers,
      ),
      action: '获取用户信息',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response, action: '获取用户信息');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      action: '更新个人资料',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response, action: '更新个人资料');
    }
  }

  // ── Goals APIs ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGoals() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals'),
        headers: _headers,
      ),
      action: '获取目标列表',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      _throwFriendlyError(response, action: '获取目标列表');
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals'),
        headers: _headers,
        body: jsonEncode(goalData),
      ),
      action: '创建目标',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _throwFriendlyError(response, action: '创建目标');
    }
  }

  Future<Map<String, dynamic>> getGoal(String id) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals/$id'),
        headers: _headers,
      ),
      action: '获取目标详情',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _throwFriendlyError(response, action: '获取目标详情');
    }
  }

  Future<GoalDecomposition> decompose(Map<String, dynamic> goalData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals/decompose'),
        headers: _headers,
        body: jsonEncode(goalData),
      ),
      action: 'AI 拆解',
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode == 200) {
      return GoalDecomposition.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      _throwFriendlyError(response, action: 'AI 拆解');
    }
  }

  Future<Map<String, dynamic>> updateGoal(
      String id, Map<String, dynamic> goalData) async {
    final response = await _send(
      () => http.patch(
        Uri.parse('$baseUrl/api/goals/$id'),
        headers: _headers,
        body: jsonEncode(goalData),
      ),
      action: '更新目标',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _throwFriendlyError(response, action: '更新目标');
    }
  }

  Future<void> deleteGoal(String id) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/api/goals/$id'),
        headers: _headers,
      ),
      action: '删除目标',
    );
    if (response.statusCode != 204) {
      _throwFriendlyError(response, action: '删除目标');
    }
  }

  Future<void> checkIn(String goalId, Map<String, dynamic> checkInData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals/$goalId/checkin'),
        headers: _headers,
        body: jsonEncode(checkInData),
      ),
      action: '完成任务',
    );
    if (response.statusCode != 200) {
      _throwFriendlyError(response, action: '完成任务');
    }
  }

  Future<void> deferTask(String goalId, Map<String, dynamic> deferData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals/$goalId/defer'),
        headers: _headers,
        body: jsonEncode(deferData),
      ),
      action: '顺延任务',
    );
    if (response.statusCode != 200) {
      _throwFriendlyError(response, action: '顺延任务');
    }
  }

  Future<List<Map<String, dynamic>>> getGoalTimeline(String goalId) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals/$goalId/timeline'),
        headers: _headers,
      ),
      action: '获取任务进度',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      _throwFriendlyError(response, action: '获取任务进度');
    }
  }

  Future<Map<String, dynamic>?> getDailyReview(String date) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/daily-reviews/$date'),
        headers: _headers,
      ),
      action: '获取每日复盘',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      return null;
    }
    _throwFriendlyError(response, action: '获取每日复盘');
  }

  Future<Map<String, dynamic>> upsertDailyReview(
    String date,
    Map<String, dynamic> payload,
  ) async {
    final response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/api/daily-reviews/$date'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
      action: '保存每日复盘',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: '保存每日复盘');
  }

  Future<List<String>> getDailyReviewCalendar(String month) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/daily-reviews/calendar?month=$month'),
        headers: _headers,
      ),
      action: '获取复盘月历',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final dates = (data['reviewedDates'] as List? ?? const []);
      return dates.map((item) => item.toString()).toList(growable: false);
    }
    _throwFriendlyError(response, action: '获取复盘月历');
  }

  Future<List<Map<String, dynamic>>> getHabits() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/habits'),
        headers: _headers,
      ),
      action: '获取习惯列表',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    _throwFriendlyError(response, action: '获取习惯列表');
  }

  Future<Map<String, dynamic>> createHabit(Map<String, dynamic> payload) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/habits'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
      action: '创建习惯',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: '创建习惯');
  }

  Future<Map<String, dynamic>> updateHabit(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _send(
      () => http.patch(
        Uri.parse('$baseUrl/api/habits/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
      action: '更新习惯',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: '更新习惯');
  }

  Future<void> deleteHabit(String id) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/api/habits/$id'),
        headers: _headers,
      ),
      action: '删除习惯',
    );
    if (response.statusCode != 204) {
      _throwFriendlyError(response, action: '删除习惯');
    }
  }

  Future<void> setHabitCheckin(
    String habitId,
    String date,
    bool isDone,
  ) async {
    final response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/api/habits/$habitId/checkins/$date'),
        headers: _headers,
        body: jsonEncode({'isDone': isDone}),
      ),
      action: isDone ? '习惯打卡' : '取消习惯打卡',
    );
    if (response.statusCode != 200) {
      _throwFriendlyError(response, action: isDone ? '习惯打卡' : '取消习惯打卡');
    }
  }

  Future<List<Map<String, dynamic>>> getHabitCheckins(String month) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/habits/checkins?month=$month'),
        headers: _headers,
      ),
      action: '获取习惯月历',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['checkins'] as List? ?? const []);
      return items
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
    }
    _throwFriendlyError(response, action: '获取习惯月历');
  }

  Future<Map<String, dynamic>> exportAccountData() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/account/export'),
        headers: _headers,
      ),
      action: '导出数据',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: '导出数据');
  }

  Future<void> clearHistory() async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/api/account/history'),
        headers: _headers,
      ),
      action: '清空历史',
    );
    if (response.statusCode != 204) {
      _throwFriendlyError(response, action: '清空历史');
    }
  }
}
