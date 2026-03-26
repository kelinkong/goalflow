class GoalPhase {
  final String title;
  final int startDay;
  final int endDay;
  final String focus;

  const GoalPhase({
    required this.title,
    required this.startDay,
    required this.endDay,
    required this.focus,
  });

  factory GoalPhase.fromJson(Map<String, dynamic> json) {
    return GoalPhase(
      title: json['title']?.toString() ?? '阶段',
      startDay: (json['startDay'] as num?)?.toInt() ?? 1,
      endDay: (json['endDay'] as num?)?.toInt() ?? 1,
      focus: json['focus']?.toString() ?? '',
    );
  }
}

class GoalDecomposition {
  final List<GoalPhase> phases;
  final List<List<String>> taskPlan;

  const GoalDecomposition({
    required this.phases,
    required this.taskPlan,
  });

  factory GoalDecomposition.fromJson(Map<String, dynamic> json) {
    final days = (json['taskPlan'] as List?)
            ?.map((e) => (e as List).map((v) => v.toString()).toList())
            .toList() ??
        const <List<String>>[];

    return GoalDecomposition(
      phases: (json['phases'] as List?)
              ?.map((e) => GoalPhase.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      taskPlan: days,
    );
  }
}
