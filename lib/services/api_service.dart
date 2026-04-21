import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl =
      dotenv.get('API_BASE_URL', fallback: 'http://localhost:8081');
  String? _token;
  String languageCode = 'zh';
  VoidCallback? onUnauthorized;

  void setToken(String token) {
    _token = token.isEmpty ? null : token;
  }

  String? get token => _token;

  String? resolveAssetUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('data:image')) {
      return value;
    }

    final baseUri = Uri.parse(baseUrl);
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return baseUri
        .replace(
          path: normalizedPath,
          query: null,
          fragment: null,
        )
        .toString();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept-Language': languageCode,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String _t(String zh, String en) =>
      languageCode == 'en' ? en : zh;

  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    } catch (_) {}
    return _t(
      '请求失败 (${response.statusCode})',
      'Request failed (${response.statusCode})',
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required String action,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await request().timeout(timeout);
    } on SocketException {
      throw Exception(_t('网络连接失败，请检查网络后重试',
          'Network connection failed. Check your network and try again.'));
    } on TimeoutException {
      throw Exception(_t('$action超时，请稍后重试',
          '$action timed out. Please try again shortly.'));
    } on http.ClientException {
      throw Exception(
          _t('网络请求失败，请稍后重试', 'Network request failed. Please try again shortly.'));
    } on FormatException {
      throw Exception(_t('服务器返回异常，请稍后重试',
          'The server returned an invalid response. Please try again shortly.'));
    }
  }

  Never _throwFriendlyError(http.Response response, {required String action}) {
    final rawMessage = _parseErrorMessage(response);
    final status = response.statusCode;

    if (status == 401) {
      if (action != _t('登录', 'Sign in') && action != _t('注册', 'Sign up')) {
        onUnauthorized?.call();
      }
      if (action == _t('登录', 'Sign in')) {
        throw Exception(_t('邮箱或密码不正确', 'Incorrect email or password.'));
      }
      throw Exception(
          _t('登录状态已过期，请重新登录', 'Your session has expired. Please sign in again.'));
    }

    if (status == 403) {
      if (rawMessage.contains('登录状态已过期')) {
        if (action != _t('登录', 'Sign in') && action != _t('注册', 'Sign up')) {
          onUnauthorized?.call();
        }
        throw Exception(
            _t('登录状态已过期，请重新登录', 'Your session has expired. Please sign in again.'));
      }
      if (rawMessage.isNotEmpty &&
          rawMessage != _t('请求失败 ($status)', 'Request failed ($status)')) {
        throw Exception(rawMessage);
      }
      throw Exception(_t('$action失败，当前无权限', '$action failed because access is denied.'));
    }

    if (status == 404) {
      throw Exception(_t('$action失败，内容不存在或已被删除',
          '$action failed because the content was not found or has been removed.'));
    }

    if (status == 408 || status == 504) {
      throw Exception(_t('$action超时，请稍后重试',
          '$action timed out. Please try again shortly.'));
    }

    if (status >= 500) {
      if (action == _t('AI 拆解', 'AI breakdown') ||
          rawMessage.contains('AI decomposition failed')) {
        throw Exception(
            _t('AI 拆解失败，请稍后重试', 'AI breakdown failed. Please try again shortly.'));
      }
      throw Exception(_t('$action失败，服务器暂时不可用',
          '$action failed because the server is temporarily unavailable.'));
    }

    if (rawMessage.isNotEmpty &&
        rawMessage != _t('请求失败 ($status)', 'Request failed ($status)')) {
      throw Exception(rawMessage);
    }

    throw Exception(_t('$action失败，请稍后重试',
        '$action failed. Please try again shortly.'));
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
      action: _t('登录', 'Sign in'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception(_t('登录失败：Token 缺失',
            'Sign-in failed: missing token in response.'));
      }
      return {'token': token};
    } else {
      _throwFriendlyError(response, action: _t('登录', 'Sign in'));
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
      action: _t('注册', 'Sign up'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        return {'token': token};
      }
      return {'message': response.body};
    } else {
      _throwFriendlyError(response, action: _t('注册', 'Sign up'));
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers,
      ),
      action: _t('获取用户信息', 'Load profile'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response, action: _t('获取用户信息', 'Load profile'));
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      action: _t('更新个人资料', 'Update profile'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response, action: _t('更新个人资料', 'Update profile'));
    }
  }

  // ── Goals APIs ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getGoals({int page = 1, int size = 10}) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals?page=$page&size=$size'),
        headers: _headers,
      ),
      action: _t('获取目标列表', 'Load goals'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response, action: _t('获取目标列表', 'Load goals'));
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals'),
        headers: _headers,
        body: jsonEncode(goalData),
      ),
      action: _t('创建目标', 'Create goal'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _throwFriendlyError(response, action: _t('创建目标', 'Create goal'));
    }
  }

  Future<Map<String, dynamic>> getGoal(String id) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals/$id'),
        headers: _headers,
      ),
      action: _t('获取目标详情', 'Load goal details'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _throwFriendlyError(
          response, action: _t('获取目标详情', 'Load goal details'));
    }
  }

  Future<Map<String, dynamic>> decompose(Map<String, dynamic> goalData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals/decompose'),
        headers: _headers,
        body: jsonEncode(goalData),
      ),
      action: _t('提交 AI 拆解任务', 'Submit AI breakdown'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response,
          action: _t('提交 AI 拆解任务', 'Submit AI breakdown'));
    }
  }

  Future<Map<String, dynamic>> getDecomposeStatus(String taskId) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals/decompose/status/$taskId'),
        headers: _headers,
      ),
      action: _t('查询 AI 拆解进度', 'Check AI breakdown progress'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwFriendlyError(response,
          action: _t('查询 AI 拆解进度', 'Check AI breakdown progress'));
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
      action: _t('更新目标', 'Update goal'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _throwFriendlyError(response, action: _t('更新目标', 'Update goal'));
    }
  }

  Future<void> deleteGoal(String id) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/api/goals/$id'),
        headers: _headers,
      ),
      action: _t('删除目标', 'Delete goal'),
    );
    if (response.statusCode != 204) {
      _throwFriendlyError(response, action: _t('删除目标', 'Delete goal'));
    }
  }

  Future<void> checkIn(String goalId, Map<String, dynamic> checkInData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals/$goalId/checkin'),
        headers: _headers,
        body: jsonEncode(checkInData),
      ),
      action: _t('完成任务', 'Complete task'),
    );
    if (response.statusCode != 200) {
      _throwFriendlyError(response, action: _t('完成任务', 'Complete task'));
    }
  }

  Future<void> deferTask(String goalId, Map<String, dynamic> deferData) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/goals/$goalId/defer'),
        headers: _headers,
        body: jsonEncode(deferData),
      ),
      action: _t('顺延任务', 'Defer task'),
    );
    if (response.statusCode != 200) {
      _throwFriendlyError(response, action: _t('顺延任务', 'Defer task'));
    }
  }

  Future<List<Map<String, dynamic>>> getGoalTimeline(String goalId) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/goals/$goalId/timeline'),
        headers: _headers,
      ),
      action: _t('获取任务进度', 'Load timeline'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      _throwFriendlyError(response, action: _t('获取任务进度', 'Load timeline'));
    }
  }

  Future<Map<String, dynamic>?> getDailyReview(String date) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/daily-reviews/$date'),
        headers: _headers,
      ),
      action: _t('获取每日复盘', 'Load daily review'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      return null;
    }
    _throwFriendlyError(response, action: _t('获取每日复盘', 'Load daily review'));
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
      action: _t('保存每日复盘', 'Save daily review'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: _t('保存每日复盘', 'Save daily review'));
  }

  Future<List<String>> getDailyReviewCalendar(String month) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/daily-reviews/calendar?month=$month'),
        headers: _headers,
      ),
      action: _t('获取复盘月历', 'Load review calendar'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final dates = (data['reviewedDates'] as List? ?? const []);
      return dates.map((item) => item.toString()).toList(growable: false);
    }
    _throwFriendlyError(
        response, action: _t('获取复盘月历', 'Load review calendar'));
  }

  Future<List<Map<String, dynamic>>> getHabits() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/habits'),
        headers: _headers,
      ),
      action: _t('获取习惯列表', 'Load habits'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    _throwFriendlyError(response, action: _t('获取习惯列表', 'Load habits'));
  }

  Future<Map<String, dynamic>> createHabit(Map<String, dynamic> payload) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/api/habits'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
      action: _t('创建习惯', 'Create habit'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: _t('创建习惯', 'Create habit'));
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
      action: _t('更新习惯', 'Update habit'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: _t('更新习惯', 'Update habit'));
  }

  Future<void> deleteHabit(String id) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/api/habits/$id'),
        headers: _headers,
      ),
      action: _t('删除习惯', 'Delete habit'),
    );
    if (response.statusCode != 204) {
      _throwFriendlyError(response, action: _t('删除习惯', 'Delete habit'));
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
      action: isDone
          ? _t('习惯打卡', 'Check in habit')
          : _t('取消习惯打卡', 'Undo habit check-in'),
    );
    if (response.statusCode != 200) {
      _throwFriendlyError(
        response,
        action: isDone
            ? _t('习惯打卡', 'Check in habit')
            : _t('取消习惯打卡', 'Undo habit check-in'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getHabitCheckins(String month) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/habits/checkins?month=$month'),
        headers: _headers,
      ),
      action: _t('获取习惯月历', 'Load habit calendar'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['checkins'] as List? ?? const []);
      return items
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
    }
    _throwFriendlyError(
        response, action: _t('获取习惯月历', 'Load habit calendar'));
  }

  Future<Map<String, dynamic>> exportAccountData() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/api/account/export'),
        headers: _headers,
      ),
      action: _t('导出数据', 'Export data'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFriendlyError(response, action: _t('导出数据', 'Export data'));
  }

  Future<void> clearHistory() async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/api/account/history'),
        headers: _headers,
      ),
      action: _t('清空历史', 'Clear history'),
    );
    if (response.statusCode != 204) {
      _throwFriendlyError(response, action: _t('清空历史', 'Clear history'));
    }
  }
}
