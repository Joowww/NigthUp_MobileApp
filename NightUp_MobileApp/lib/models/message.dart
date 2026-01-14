enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, audio }

class Message {
  final String id;
  final String conversationId;
  final Sender sender;
  final String text;
  final MessageType messageType;
  final String? imageUrl;
  final String? audioUrl;
  final bool isEdited;
  final bool isDeleted;
  final Message? replyTo;
  final List<Reaction> reactions;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MessageStatus status;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.audioUrl,
    this.isEdited = false,
    this.isDeleted = false,
    this.replyTo,
    this.reactions = const [],
    this.readBy = const [],
    required this.createdAt,
    this.updatedAt,
    this.status = MessageStatus.sent,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    Sender? sender,
    String? text,
    MessageType? messageType,
    String? imageUrl,
    String? audioUrl,
    bool? isEdited,
    bool? isDeleted,
    Message? replyTo,
    List<Reaction>? reactions,
    List<String>? readBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final readByList =
        (json['readBy'] as List?)?.map((r) => r.toString()).toList() ?? [];

    MessageStatus status = MessageStatus.sent;
    if (readByList.isNotEmpty) {
      status = MessageStatus.read;
    }

    // Determinar tipo de mensaje
    MessageType type = MessageType.text;
    if (json['messageType'] == 'image') {
      type = MessageType.image;
    } else if (json['messageType'] == 'audio') {
      type = MessageType.audio;
    }

    return Message(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      conversationId: json['conversation']?.toString() ?? '',
      sender: Sender.fromJson(json['sender'] ?? {}),
      text: json['text'] ?? json['content'] ?? '',
      messageType: type,
      imageUrl: json['imageUrl'] ?? json['file_url'] ?? json['url'],
      audioUrl: json['audioUrl'] ?? json['file_url'] ?? json['url'],
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      replyTo: json['replyTo'] != null
          ? Message.fromJson(json['replyTo'])
          : null,
      reactions:
          (json['reactions'] as List?)
              ?.map((r) => Reaction.fromJson(r))
              .toList() ??
          [],
      readBy: readByList,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation': conversationId,
    'sender': {
      '_id': sender.id,
      'username': sender.username,
      'avatar': sender.avatar,
    },
    'text': text,
    'messageType': messageType.name,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'isEdited': isEdited,
    'isDeleted': isDeleted,
    'replyTo': replyTo?.toJson(),
    'reactions': reactions.map((r) => r.toJson()).toList(),
    'readBy': readBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  String get displayText {
    if (isDeleted) return 'Mensaje eliminado';
    if (messageType == MessageType.image) return '📷 Imagen';
    if (messageType == MessageType.audio) return '🎤 Audio';
    return text;
  }

  bool get isImage => messageType == MessageType.image;
  bool get isAudio => messageType == MessageType.audio;
}

class Sender {
  final String id;
  final String username;
  final String? avatar;

  Sender({required this.id, required this.username, this.avatar});

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? json['name'] ?? 'Usuario',
      avatar: json['avatar'] ?? json['profilePictureUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'username': username,
    'avatar': avatar,
  };
}

class Reaction {
  final String userId;
  final String emoji;

  Reaction({required this.userId, required this.emoji});

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      userId: json['user']?.toString() ?? '',
      emoji: json['emoji'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'user': userId, 'emoji': emoji};
}
