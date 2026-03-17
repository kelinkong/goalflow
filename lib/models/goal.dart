import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 0)
class Goal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  late String desc;

  @HiveField(4)
  late int totalDays;

  @HiveField(5)
  late int completedDays;

  @HiveField(6)
  late String status; // active | paused | done

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late List<String> taskTemplates; // task text templates (AI-generated)

  @HiveField(9)
  late List<List<String>> taskPlan; // per-day tasks, length = totalDays

  @HiveField(10)
  String? difficulty; // 轻松/标准/挑战/高强度

  @HiveField(11)
  String? taskCount; // 少/中/多

  @HiveField(12)
  List<String> constraints; // optional constraints

  @HiveField(13)
  List<int> weeklyRestWeekdays; // 1=Mon ... 7=Sun

  Goal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.totalDays,
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

  int get remainingDays => totalDays - completedDays;
  double get progress => totalDays > 0 ? completedDays / totalDays : 0;
  int get progressPercent => (progress * 100).round();

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isDone => status == 'done';

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
}
