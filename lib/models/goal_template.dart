class GoalTemplate {
  final String id;
  final String name;
  final String description;
  final int totalDays;
  final String visibility;
  final String status;
  final String tags;
  final String ownerNickname;
  final int totalTasks;
  final List<List<String>> taskPlan;

  const GoalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.totalDays,
    required this.visibility,
    required this.status,
    required this.tags,
    required this.ownerNickname,
    required this.totalTasks,
    required this.taskPlan,
  });

  factory GoalTemplate.fromJson(Map<String, dynamic> json) {
    return GoalTemplate(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      visibility: json['visibility']?.toString() ?? 'PRIVATE',
      status: json['status']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
      ownerNickname: json['ownerNickname']?.toString() ?? '',
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      taskPlan: (json['taskPlan'] as List?)
              ?.map((e) => (e as List).map((v) => v.toString()).toList())
              .toList() ??
          const [],
    );
  }

  List<String> get tagList => tags
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();

  bool get isPublic => visibility.toUpperCase() == 'PUBLIC';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isPrivateDraft => !isPublic && !isPending && !isRejected;

  GoalTemplate copyWith({
    String? id,
    String? name,
    String? description,
    int? totalDays,
    String? visibility,
    String? status,
    String? tags,
    String? ownerNickname,
    int? totalTasks,
    List<List<String>>? taskPlan,
  }) {
    return GoalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalDays: totalDays ?? this.totalDays,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      ownerNickname: ownerNickname ?? this.ownerNickname,
      totalTasks: totalTasks ?? this.totalTasks,
      taskPlan: taskPlan ?? this.taskPlan.map((day) => List<String>.from(day)).toList(),
    );
  }
}
