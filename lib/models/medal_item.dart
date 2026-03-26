class MedalItem {
  final String id;
  final String goalId;
  final String title;
  final String goalName;
  final String goalEmoji;
  final DateTime awardedAt;

  const MedalItem({
    required this.id,
    required this.goalId,
    required this.title,
    required this.goalName,
    required this.goalEmoji,
    required this.awardedAt,
  });

  factory MedalItem.fromJson(Map<String, dynamic> json) {
    return MedalItem(
      id: json['id'].toString(),
      goalId: json['goalId'].toString(),
      title: json['title']?.toString() ?? '完成勋章',
      goalName: json['goalName']?.toString() ?? '',
      goalEmoji: json['goalEmoji']?.toString() ?? '🏅',
      awardedAt: json['awardedAt'] != null
          ? DateTime.parse(json['awardedAt'].toString())
          : DateTime.now(),
    );
  }
}
