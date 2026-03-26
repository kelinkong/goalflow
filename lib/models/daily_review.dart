enum DailyReviewDimension {
  workStudy('WORK_STUDY', '工作/学业'),
  health('HEALTH', '健康'),
  relationship('RELATIONSHIP', '人际关系'),
  hobby('HOBBY', '爱好');

  const DailyReviewDimension(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DailyReviewDimension fromApiValue(String value) {
    return DailyReviewDimension.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => DailyReviewDimension.workStudy,
    );
  }
}

enum DailyReviewStatus {
  good('GOOD', '好'),
  normal('NORMAL', '一般'),
  bad('BAD', '差');

  const DailyReviewStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DailyReviewStatus fromApiValue(String value) {
    return DailyReviewStatus.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => DailyReviewStatus.normal,
    );
  }
}

class DailyReviewItem {
  final DailyReviewDimension dimension;
  final DailyReviewStatus? status;
  final String comment;

  const DailyReviewItem({
    required this.dimension,
    this.status,
    this.comment = '',
  });

  factory DailyReviewItem.fromJson(Map<String, dynamic> json) {
    return DailyReviewItem(
      dimension: DailyReviewDimension.fromApiValue(
        json['dimension']?.toString() ?? '',
      ),
      status: json['status'] == null
          ? null
          : DailyReviewStatus.fromApiValue(json['status'].toString()),
      comment: json['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimension': dimension.apiValue,
      'status': status?.apiValue,
      'comment': comment,
    };
  }

  DailyReviewItem copyWith({
    DailyReviewDimension? dimension,
    DailyReviewStatus? status,
    String? comment,
  }) {
    return DailyReviewItem(
      dimension: dimension ?? this.dimension,
      status: status ?? this.status,
      comment: comment ?? this.comment,
    );
  }
}

class DailyReview {
  final String? id;
  final DateTime date;
  final String tomorrowTopPriority;
  final List<DailyReviewItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyReview({
    this.id,
    required this.date,
    required this.tomorrowTopPriority,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyReview.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List? ?? const [])
        .map((item) => DailyReviewItem.fromJson(
              (item as Map).cast<String, dynamic>(),
            ))
        .toList();
    final byDimension = <DailyReviewDimension, DailyReviewItem>{
      for (final item in rawItems) item.dimension: item,
    };
    final items = DailyReviewDimension.values
        .map((dimension) =>
            byDimension[dimension] ?? DailyReviewItem(dimension: dimension))
        .toList(growable: false);

    return DailyReview(
      id: json['id']?.toString(),
      date: DateTime.parse(json['date'].toString()),
      tomorrowTopPriority: json['tomorrowTopPriority']?.toString() ?? '',
      items: items,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  factory DailyReview.empty(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return DailyReview(
      date: normalized,
      tomorrowTopPriority: '',
      items: DailyReviewDimension.values
          .map((dimension) => DailyReviewItem(dimension: dimension))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': _dateKey(date),
      'tomorrowTopPriority': tomorrowTopPriority,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  DailyReview copyWith({
    String? id,
    DateTime? date,
    String? tomorrowTopPriority,
    List<DailyReviewItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReview(
      id: id ?? this.id,
      date: date ?? this.date,
      tomorrowTopPriority: tomorrowTopPriority ?? this.tomorrowTopPriority,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String _dateKey(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}
