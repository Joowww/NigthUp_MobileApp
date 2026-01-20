class GroupParticipant {
  final String userId;
  final String username;
  final String? avatar;
  final String role;
  final DateTime? joinedAt;

  GroupParticipant({
    required this.userId,
    required this.username,
    this.avatar,
    required this.role,
    this.joinedAt,
  });

  factory GroupParticipant.fromJson(Map<String, dynamic> json) {
    final participantData = json['participant'] is Map
        ? json['participant']
        : json;

    return GroupParticipant(
      userId:
          participantData['_id']?.toString() ??
          participantData['id']?.toString() ??
          '',
      username:
          participantData['username'] ?? participantData['name'] ?? 'Usuario',
      avatar: participantData['avatar'],
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : null,
    );
  }

  bool get isCreator => role == 'creator';
  bool get isAdmin => role == 'creator';
}
