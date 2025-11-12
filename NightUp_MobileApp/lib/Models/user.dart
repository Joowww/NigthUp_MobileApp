class User {
  final String id;
  final String username;
  final String gmail;
  final String birthday;
  final String? password;
  final String? token;
  final String? refreshToken;

  User({
    required this.id,
    required this.username,
    required this.gmail,
    required this.birthday,
    this.password,
    this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      gmail: json['gmail'] ?? '',
      birthday: json['birthday'] ?? '',
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'gmail': gmail,
      'birthday': birthday,
      if (password != null) 'password': password,
    };
  }
}