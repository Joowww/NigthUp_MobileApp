import 'dart:convert';

class User {
  final String id;
  final String username;
  final String email;
  final String? phoneNumber;
  final DateTime? birthday;
  final String role;
  final bool active;
  final String? authProvider;
  final String? googleId;
  final Map<String, dynamic>? googleProfile;
  final String? securityQuestion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profilePictureUrl;
  final String? avatar;
  final String? coverPhoto;
  final String? bio;
  final String? city;
  final String? country;
  final String? website;
  final Map<String, dynamic>? socialMedia;
  final List<String>? friends;
  final List<String>? interests;
  final String? gender;
  final String? firstName;
  final String? lastName;
  final bool? isVisibleOnMap;
  final Map<String, dynamic>? location;
  final List<String>? posts;
  final List<String>? events;
  final List<String>? emergencyContacts;
  final bool? isOnline;
  final DateTime? lastSeen;
  final DateTime? lastLocationUpdate;
  final bool? onboardingCompleted;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.birthday,
    required this.role,
    required this.active,
    this.authProvider,
    this.googleId,
    this.googleProfile,
    this.securityQuestion,
    this.createdAt,
    this.updatedAt,
    this.profilePictureUrl,
    this.avatar,
    this.coverPhoto,
    this.bio,
    this.city,
    this.country,
    this.website,
    this.socialMedia,
    this.friends,
    this.interests,
    this.gender,
    this.firstName,
    this.lastName,
    this.isVisibleOnMap,
    this.location,
    this.posts,
    this.events,
    this.emergencyContacts,
    this.isOnline,
    this.lastSeen,
    this.lastLocationUpdate,
    this.onboardingCompleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Si la respuesta viene envuelta en un campo 'user' o 'data', extraerlo
    if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      json = json['user'];
    } else if (json.containsKey('data') &&
        json['data'] is Map<String, dynamic>) {
      json = json['data'];
    }

    // ✅ Manejar intereses extrayendo SOLO el campo 'name'
    List<String>? parsedInterests;
    if (json['interests'] != null) {
      try {
        parsedInterests = List<String>.from(
          json['interests'].map((i) {
            if (i == null) return 'Unknown';

            if (i is String) {
              // Si es un string que parece un mapa JSON, parsearlo
              if (i.trim().startsWith('{') && i.trim().endsWith('}')) {
                try {
                  final normalized = i
                      .replaceAllMapped(
                        RegExp(r'(\w+):'),
                        (match) => '"${match[1]}":',
                      )
                      .replaceAll("'", '"');
                  final map = Map<String, dynamic>.from(jsonDecode(normalized));
                  // ✅ Extraer SOLO el campo 'name'
                  return map['name']?.toString() ?? 'Unknown';
                } catch (_) {
                  return i;
                }
              }
              return i;
            } else if (i is Map) {
              // ✅ Si es un Map directo, extraer SOLO el campo 'name'
              return i['name']?.toString() ?? 'Unknown';
            } else {
              return i.toString();
            }
          }),
        );
      } catch (e) {
        print('Error parsing interests: $e');
        parsedInterests = null;
      }
    }

    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'].toString())
          : null,
      role: json['role'] ?? 'user',
      active: json['active'] ?? true,
      authProvider: json['authProvider'],
      googleId: json['googleId'],
      googleProfile: json['googleProfile'] != null
          ? Map<String, dynamic>.from(json['googleProfile'])
          : null,
      securityQuestion: json['securityQuestion'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      profilePictureUrl:
          json['profilePictureUrl'] ??
          json['profilePicture'] ??
          json['avatar'] ??
          json['avatarUrl'] ??
          json['avatar_url'],
      avatar:
          json['avatar'] ?? json['profilePictureUrl'] ?? json['profilePicture'],
      coverPhoto:
          json['coverPhoto'] ??
          json['cover_photo'] ??
          json['cover'] ??
          json['coverPhotoUrl'],
      bio: json['bio'],
      city: json['city'],
      country: json['country'],
      website: json['website'],
      socialMedia: json['socialMedia'] != null
          ? Map<String, dynamic>.from(json['socialMedia'])
          : null,
      friends: json['friends'] != null
          ? List<String>.from(json['friends'].map((f) => f.toString()))
          : null,
      interests: parsedInterests,
      gender: json['gender'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      isVisibleOnMap: json['isVisibleOnMap'],
      location: json['location'] != null
          ? Map<String, dynamic>.from(json['location'])
          : null,
      posts: json['posts'] != null
          ? List<String>.from(json['posts'].map((p) => p.toString()))
          : null,
      events: json['events'] != null
          ? List<String>.from(json['events'].map((e) => e.toString()))
          : null,
      emergencyContacts: json['emergencyContacts'] != null
          ? List<String>.from(json['emergencyContacts'])
          : null,
      isOnline: json['isOnline'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.tryParse(json['lastLocationUpdate'].toString())
          : null,
      onboardingCompleted: json['onboardingCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthday': birthday?.toIso8601String(),
      'role': role,
      'active': active,
      'authProvider': authProvider,
      'googleId': googleId,
      'googleProfile': googleProfile,
      'securityQuestion': securityQuestion,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profilePictureUrl': profilePictureUrl,
      'avatar': avatar,
      'coverPhoto': coverPhoto,
      'bio': bio,
      'city': city,
      'country': country,
      'website': website,
      'socialMedia': socialMedia,
      'friends': friends,
      'interests': interests,
      'gender': gender,
      'firstName': firstName,
      'lastName': lastName,
      'isVisibleOnMap': isVisibleOnMap,
      'location': location,
      'posts': posts,
      'events': events,
      'emergencyContacts': emergencyContacts,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
    };
  }

  String? get safeProfilePictureUrl {
    final url = profilePictureUrl?.isNotEmpty == true
        ? profilePictureUrl
        : (avatar?.isNotEmpty == true ? avatar : null);

    // Si es una ruta de asset, devolvemos null para que el widget use su propio fallback
    if (url == null || url.isEmpty || url.startsWith('assets/')) {
      return null;
    }
    return url;
  }

  String? get safeCoverPhoto {
    if (coverPhoto == null ||
        coverPhoto!.isEmpty ||
        coverPhoto!.startsWith('assets/')) {
      return null;
    }
    return coverPhoto!;
  }

  Object? get safeLocationString {
    if (location == null) return '';
    if (location is String) return location;
    if (location is Map && location?['name'] != null)
      return location?['name'].toString();
    return location.toString();
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final DateTime birthday;
  final String securityQuestionKey;
  final String securityAnswer;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.birthday,
    required this.securityQuestionKey,
    required this.securityAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'birthday': birthday.toIso8601String(),
      'securityQuestionKey': securityQuestionKey,
      'securityAnswer': securityAnswer,
    };
  }
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class VerifySecurityAnswerRequest {
  final String email;
  final String securityAnswer;

  VerifySecurityAnswerRequest({
    required this.email,
    required this.securityAnswer,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'securityAnswer': securityAnswer};
  }
}

class ResetPasswordRequest {
  final String resetToken;
  final String newPassword;

  ResetPasswordRequest({required this.resetToken, required this.newPassword});

  Map<String, dynamic> toJson() {
    return {'resetToken': resetToken, 'newPassword': newPassword};
  }
}

class AuthResponse {
  final User user;
  final String token;
  final String refreshToken;
  final String message;
  final bool isNewUser;

  AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
    required this.message,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
      refreshToken: json['refreshToken'],
      message: json['message'],
      isNewUser: json['isNewUser'] ?? false,
    );
  }
}

class SecurityQuestionResponse {
  final List<String> securityQuestionKeys;
  final Map<String, String>? fallbackTexts;

  SecurityQuestionResponse({
    required this.securityQuestionKeys,
    this.fallbackTexts,
  });

  factory SecurityQuestionResponse.fromJson(Map<String, dynamic> json) {
    return SecurityQuestionResponse(
      securityQuestionKeys: List<String>.from(json['securityQuestionKeys']),
      fallbackTexts: json['fallbackTexts'] != null
          ? Map<String, String>.from(json['fallbackTexts'])
          : null,
    );
  }
}

class ForgotPasswordResponse {
  final String message;
  final String? securityQuestionKey;
  final String? email;

  ForgotPasswordResponse({
    required this.message,
    this.securityQuestionKey,
    this.email,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message'],
      securityQuestionKey: json['securityQuestionKey'],
      email: json['email'],
    );
  }
}

class VerifySecurityAnswerResponse {
  final String message;
  final String resetToken;

  VerifySecurityAnswerResponse({
    required this.message,
    required this.resetToken,
  });

  factory VerifySecurityAnswerResponse.fromJson(Map<String, dynamic> json) {
    return VerifySecurityAnswerResponse(
      message: json['message'],
      resetToken: json['resetToken'],
    );
  }
}
