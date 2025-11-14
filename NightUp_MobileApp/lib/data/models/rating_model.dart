class RatingModel {
  final String id; // MongoDB _id como String
  final String event; // Event ID como String
  final String username;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  RatingModel({
    required this.id,
    required this.event,
    required this.username,
    required this.score,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    try {
      // Extraer el event ID correctamente
      String eventId = '';
      if (json['event'] is String) {
        eventId = json['event'];
      } else if (json['event'] is Map<String, dynamic>) {
        eventId = json['event']['_id'] ?? json['event']['id'] ?? '';
      }

      // Parsear score de manera completamente segura
      int parsedScore = 0;
      final scoreValue = json['score'];
      
      if (scoreValue is int) {
        parsedScore = scoreValue;
      } else if (scoreValue is double) {
        parsedScore = scoreValue.round();
      } else if (scoreValue is String) {
        parsedScore = int.tryParse(scoreValue) ?? 0;
      } else if (scoreValue != null) {
        try {
          parsedScore = int.tryParse(scoreValue.toString()) ?? 0;
        } catch (e) {
          print('Warning: Error parsing score for rating ${json['_id']}: $e');
          parsedScore = 0;
        }
      }

      final rating = RatingModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        event: eventId,
        username: json['username']?.toString() ?? '',
        score: parsedScore,
        comment: json['comment']?.toString(),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt']) 
            : DateTime.now(),
      );
      
      return rating;
    } catch (e) {
      print('Error in RatingModel.fromJson: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'event': event,
      'username': username,
      'score': score,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}