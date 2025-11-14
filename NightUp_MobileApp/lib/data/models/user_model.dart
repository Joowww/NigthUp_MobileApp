class UserModel {
  final String id; // Cambio de int a String para MongoDB _id
  final String username;
  final String email;
  final String? birthday;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final List<String> events;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.birthday,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.active = true,
    this.events = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del campo events que puede ser array de strings o array de objetos
    List<String> eventsList = [];
    if (json['events'] != null) {
      for (var event in json['events']) {
        if (event is String) {
          eventsList.add(event);
        } else if (event is Map<String, dynamic> && event['_id'] != null) {
          eventsList.add(event['_id'].toString());
        }
      }
    }

    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      birthday: json['birthday'],
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      active: json['active'] ?? true,
      events: eventsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'birthday': birthday,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
      'events': events,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? birthday,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    List<String>? events,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      birthday: birthday ?? this.birthday,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      events: events ?? this.events,
    );
  }
}