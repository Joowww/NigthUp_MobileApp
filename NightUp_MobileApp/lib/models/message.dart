// lib/models/message.dart
class Message {
  final String id;
  final String conversationId;
  final Sender sender;
  final String text;
  final bool isEdited;
  final bool isDeleted;
  final Message? replyTo;
  final List<Reaction> reactions;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    this.isEdited = false,
    this.isDeleted = false,
    this.replyTo,
    this.reactions = const [],
    this.readBy = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      conversationId: json['conversation']?.toString() ?? '',
      sender: Sender.fromJson(json['sender'] ?? {}),
      text: json['text'] ?? json['content'] ?? '',
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      replyTo: json['replyTo'] != null 
          ? Message.fromJson(json['replyTo'])
          : null,
      reactions: (json['reactions'] as List?)
          ?.map((r) => Reaction.fromJson(r))
          .toList() ?? [],
      readBy: (json['readBy'] as List?)
          ?.map((r) => r.toString())
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') 
          ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  String get displayText => isDeleted ? 'Mensaje eliminado' : text;
}

class Sender {
  final String id;
  final String username;
  final String? avatar;

  Sender({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? json['name'] ?? 'Usuario',
      avatar: json['avatar'] ?? json['profilePictureUrl'],
    );
  }
}

class Reaction {
  final String userId;
  final String emoji;

  Reaction({
    required this.userId,
    required this.emoji,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      userId: json['user']?.toString() ?? '',
      emoji: json['emoji'] ?? '',
    );
  }
}