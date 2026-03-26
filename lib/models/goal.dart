class Goal {
  late String id;
  late String name;
  late String emoji;
  late String desc;
  late int totalDays;
  String? templateId;
  bool joinRanking;
  late int completedDays;
  late String status; // active | paused | done
  late DateTime createdAt;
  late List<String> taskTemplates; // task text templates (AI-generated)
  late List<List<String>> taskPlan; // per-day tasks, length = totalDays
  String? difficulty; // 轻松/标准/挑战/高强度
  String? taskCount; // 少/中/多
  List<String> constraints; // optional constraints
  List<int> weeklyRestWeekdays; // 1=Mon ... 7=Sun

  Goal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.totalDays,
    this.templateId,
    this.joinRanking = false,
    this.completedDays = 0,
    this.status = 'active',
    required this.createdAt,
    required this.taskTemplates,
    List<List<String>>? taskPlan,
    this.difficulty,
    this.taskCount,
    List<String>? constraints,
    List<int>? weeklyRestWeekdays,
  }) : taskPlan = taskPlan ?? const [],
       constraints = constraints ?? const [],
       weeklyRestWeekdays = weeklyRestWeekdays ?? const [];

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'].toString(),
      name: json['name'],
      emoji: json['emoji'] ?? '🎯',
      desc: json['description'] ?? '',
      totalDays: json['totalDays'],
      templateId: json['templateId']?.toString(),
      joinRanking: json['joinRanking'] == true,
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      taskTemplates: [], // Not used when taskPlan is present
      taskPlan: (json['taskPlan'] as List?)?.map((e) => (e as List).cast<String>()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': desc,
      'totalDays': totalDays,
      if (templateId != null) 'templateId': int.tryParse(templateId!),
      'joinRanking': joinRanking,
      'status': status.toUpperCase(),
      if (taskCount != null) 'taskCount': taskCount,
      'createdAt': createdAt.toIso8601String(),
      'taskPlan': taskPlan,
    };
  }

  int get remainingDays => totalDays - completedDays;
  double get progress => totalDays > 0 ? completedDays / totalDays : 0;
  int get progressPercent => (progress * 100).round();

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isDone => status == 'done' || status == 'completed' || status == 'terminated';

  // The date for day N (1-based)
  DateTime dateForDay(int day) =>
      createdAt.add(Duration(days: day - 1));

  // Which day number is today? (1-based, null if not in range)
  int? get todayDayNumber => dayNumberForDate(DateTime.now());

  int? dayNumberForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = d.difference(start).inDays;
    if (diff < 0 || diff >= totalDays) return null;
    return diff + 1;
  }

  List<String> tasksForDayNumber(int dayNum) {
    if (taskPlan.isNotEmpty && dayNum >= 1 && dayNum <= taskPlan.length) {
      return taskPlan[dayNum - 1];
    }
    return taskTemplates;
  }

  List<String> tasksForDate(DateTime date) {
    final dayNum = dayNumberForDate(date);
    if (dayNum == null) return const [];
    return tasksForDayNumber(dayNum);
  }

  Goal copyWith({
    String? id,
    String? name,
    String? emoji,
    String? desc,
    int? totalDays,
    String? templateId,
    bool? joinRanking,
    int? completedDays,
    String? status,
    DateTime? createdAt,
    List<String>? taskTemplates,
    List<List<String>>? taskPlan,
    String? difficulty,
    String? taskCount,
    List<String>? constraints,
    List<int>? weeklyRestWeekdays,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      desc: desc ?? this.desc,
      totalDays: totalDays ?? this.totalDays,
      templateId: templateId ?? this.templateId,
      joinRanking: joinRanking ?? this.joinRanking,
      completedDays: completedDays ?? this.completedDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      taskTemplates: taskTemplates ?? List<String>.from(this.taskTemplates),
      taskPlan: taskPlan ?? this.taskPlan.map((day) => List<String>.from(day)).toList(),
      difficulty: difficulty ?? this.difficulty,
      taskCount: taskCount ?? this.taskCount,
      constraints: constraints ?? List<String>.from(this.constraints),
      weeklyRestWeekdays: weeklyRestWeekdays ?? List<int>.from(this.weeklyRestWeekdays),
    );
  }
}
