import 'group_poll.dart';
import 'group_participant.dart';

class Conversation {
  final String id;
  final bool isGroup;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final List<String> participants;
  final List<GroupParticipant>? groupParticipants;
  final List<GroupPoll>? groupPolls;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.isGroup,
    required this.name,
    required this.avatar,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.participants = const [],
    this.groupParticipants,
    this.groupPolls,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    List<String> participantsList = [];
    if (json['participants'] != null) {
      participantsList = List<String>.from(
        json['participants'].map((p) {
          if (p is String) return p;
          if (p is Map && p['_id'] != null) return p['_id'].toString();
          if (p is Map && p['participant'] != null) {
            return p['participant'].toString();
          }
          return p.toString();
        }),
      );
    }

    List<GroupParticipant>? groupParticipantsList;
    if (json['groupParticipants'] != null) {
      groupParticipantsList = (json['groupParticipants'] as List)
          .map((gp) => GroupParticipant.fromJson(gp as Map<String, dynamic>))
          .toList();
    }

    List<GroupPoll>? groupPollsList;
    if (json['groupPolls'] != null) {
      groupPollsList = (json['groupPolls'] as List)
          .map((p) => GroupPoll.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return Conversation(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      isGroup: json['isGroup'] ?? false,
      name:
          json['name']?.toString() ??
          json['groupName']?.toString() ??
          'Desconocido',
      avatar:
          json['avatar']?.toString() ??
          json['groupAvatar']?.toString() ??
          'assets/images/google.png',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now(),
      participants: participantsList,
      groupParticipants: groupParticipantsList,
      groupPolls: groupPollsList,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'isGroup': isGroup,
    'name': name,
    'groupName': isGroup ? name : null,
    'avatar': avatar,
    'groupAvatar': isGroup ? avatar : null,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'participants': participants,
    'groupParticipants': groupParticipants
        ?.map((gp) => {'userId': gp.userId, 'role': gp.role})
        .toList(),
    'groupPolls': groupPolls
        ?.map(
          (p) => {
            '_id': p.id,
            'question': p.question,
            'options': p.options,
            'creator': p.creatorId,
            'isActive': p.isActive,
            'createdAt': p.createdAt.toIso8601String(),
          },
        )
        .toList(),
    'unreadCount': unreadCount,
  };

  String get displayName => name;

  String get displayAvatar {
    if (avatar.startsWith('http')) {
      return avatar;
    } else if (avatar.startsWith('/')) {
      return 'http://localhost:3000$avatar';
    }
    return avatar;
  }

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
