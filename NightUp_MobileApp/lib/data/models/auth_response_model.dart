import 'user_model.dart';

class AuthResponseModel {
  final String? token;
  final UserModel user;
  final String? message;
  final String? refreshToken;

  AuthResponseModel({
    this.token,
    required this.user,
    this.message,
    this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] ?? json['access_token'],
      refreshToken: json['refreshToken'] ?? json['refresh_token'],
      user: UserModel.fromJson(json['user']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJson(),
      'message': message,
    };
  }
}