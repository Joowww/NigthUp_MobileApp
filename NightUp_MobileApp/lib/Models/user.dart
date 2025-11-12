class User {
  final String id;
  final String username;
  final String email;
  final String birthday;
  final String role;
  final bool active;
  final List<String> events;
  final String? token;
  final String? refreshToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.birthday,
    required this.role,
    required this.active,
    required this.events,
    this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      birthday: json['birthday'] != null 
          ? DateTime.parse(json['birthday']).toIso8601String().split('T')[0]
          : '',
      role: json['role'] ?? 'user',
      active: json['active'] ?? true,
      events: List<String>.from(json['events']?.map((x) => x.toString()) ?? []),
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': '',
      'birthday': birthday,
      'role': role,
    };
  }

  Map<String, dynamic> toRegisterJson() {
    return {
      'username': username,
      'email': email,
      'password': '',
      'birthday': birthday,
      'role': 'user',
    };
  }

  String get displayRole {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Manager';
      case 'user':
      default:
        return 'Usuario';
    }
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || isAdmin;
  bool get isRegularUser => role == 'user';
}