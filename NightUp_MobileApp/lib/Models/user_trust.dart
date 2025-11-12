class UserTrust {
  final String id;
  final String rater;
  final String rated;
  final int score;
  final String? comment;
  final String context;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserTrust({
    required this.id,
    required this.rater,
    required this.rated,
    required this.score,
    this.comment,
    required this.context,
    this.createdAt,
    this.updatedAt,
  });

  factory UserTrust.fromJson(Map<String, dynamic> json) {
    return UserTrust(
      id: json['_id'] ?? '',
      rater: json['rater']?.toString() ?? '',
      rated: json['rated']?.toString() ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'],
      context: json['context'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rated': rated,
      'score': score,
      'comment': comment,
      'context': context,
    };
  }

  String get starRating {
    return '⭐' * score;
  }
}