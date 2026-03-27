class Habit {
  final String id;
  final String name;
  final String? category;
  final String status;
  final bool todayDone;
  final int streak;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Habit({
    required this.id,
    required this.name,
    this.category,
    this.status = 'active',
    this.todayDone = false,
    this.streak = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      todayDone: json['todayDone'] == true,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (category != null) 'category': category,
      'status': status.toUpperCase(),
      'todayDone': todayDone,
      'streak': streak,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? category,
    bool clearCategory = false,
    String? status,
    bool? todayDone,
    int? streak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: clearCategory ? null : (category ?? this.category),
      status: status ?? this.status,
      todayDone: todayDone ?? this.todayDone,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'active';
}
