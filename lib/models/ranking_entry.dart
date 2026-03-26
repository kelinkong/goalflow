class RankingEntry {
  final String userId;
  final String nickname;
  final String? avatar;
  final int progressPercent;
  final int rank;
  final int rankChange;

  const RankingEntry({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.progressPercent,
    required this.rank,
    required this.rankChange,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      userId: json['userId'].toString(),
      nickname: json['nickname']?.toString() ?? '匿名用户',
      avatar: json['avatar']?.toString(),
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      rankChange: (json['rankChange'] as num?)?.toInt() ?? 0,
    );
  }
}
