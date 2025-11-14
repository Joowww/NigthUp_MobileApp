class TrustModel {
  final String id; // MongoDB _id como String
  final String rater; // Cambio: raterId -> rater
  final String rated; // Cambio: ratedId -> rated
  final int score; // Cambio: trustLevel -> score
  final String? comment; // Nuevo campo del backend
  final String context; // Requerido en el backend
  final DateTime createdAt;
  final DateTime updatedAt;

  TrustModel({
    required this.id,
    required this.rater,
    required this.rated,
    required this.score,
    this.comment,
    required this.context,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrustModel.fromJson(Map<String, dynamic> json) {
    return TrustModel(
      id: json['_id'] ?? json['id'] ?? '',
      rater: json['rater'] ?? '',
      rated: json['rated'] ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'],
      context: json['context'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'rater': rater,
      'rated': rated,
      'score': score,
      'comment': comment,
      'context': context,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}