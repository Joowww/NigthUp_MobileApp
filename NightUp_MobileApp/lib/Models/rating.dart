class Rating {
  final String id;
  final String event;
  final String username;
  final int score;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rating({
    required this.id,
    required this.event,
    required this.username,
    required this.score,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['_id'] ?? '',
      event: json['event']?.toString() ?? '',
      username: json['username'] ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'username': username,
      'score': score,
      'comment': comment,
    };
  }

  String get starRating {
    return '⭐' * score;
  }
}