// lib/models/conversation.dart
class Conversation {
  final String id;
  final bool isGroup;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final List<String> participants;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.isGroup,
    required this.name,
    required this.avatar,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.participants = const [],
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    try {
      return Conversation(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        isGroup: json['isGroup'] ?? false,
        name: json['name']?.toString() ?? 'Desconocido',
        avatar: json['avatar']?.toString() ?? 'assets/images/google.png',
        lastMessage: json['lastMessage']?.toString() ?? '',
        lastMessageTime: json['lastMessageTime'] != null
            ? DateTime.parse(json['lastMessageTime'])
            : DateTime.now(),
        participants: json['participants'] != null
            ? List<String>.from(json['participants'].map((p) => p.toString()))
            : [],
        unreadCount: json['unreadCount'] ?? 0,
      );
    } catch (e) {
      print('❌ Error parsing Conversation: $e');
      print('   JSON was: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isGroup': isGroup,
    'name': name,
    'avatar': avatar,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'participants': participants,
    'unreadCount': unreadCount,
  };

  // Getter para mostrar el nombre en la UI
  String get displayName => name;

  // Getter para el avatar (maneja rutas relativas del backend)
  String get displayAvatar {
    if (avatar.startsWith('http')) {
      return avatar;
    } else if (avatar.startsWith('/')) {
      // Si el avatar es una ruta relativa del backend (como /default-images/default-avatar.png)
      return 'http://localhost:3000$avatar'; // Cambia esto por tu URL del backend
    }
    return avatar;
  }

  // Método para obtener el tiempo formateado
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}a';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'ahora';
    }
  }

  @override
  String toString() {
    return 'Conversation(id: $id, name: $name, isGroup: $isGroup, lastMessage: $lastMessage)';
  }
}
