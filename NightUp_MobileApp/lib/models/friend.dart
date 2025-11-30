
import 'package:get/get.dart';
import '../services/api_service.dart';

class Friend {
  final String id;
  final String username;
  final String? profilePictureUrl;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final double? distance;

  Friend({
    required this.id,
    required this.username,
    this.profilePictureUrl,
    this.isOnline = false,
    this.lat,
    this.lng,
    this.distance,
  });

  factory Friend.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Si el objeto es una relación de amistad (tiene requester/recipient), extraer el amigo
    if (json.containsKey('requester') && json.containsKey('recipient')) {
      String? userId = currentUserId;
      if (userId == null) {
        try {
          if (Get.isRegistered<ApiService>()) {
            final apiService = Get.find<ApiService>();
            userId = apiService.getUserId();
          }
        } catch (_) {}
      }
      Map<String, dynamic> userJson;
      if (userId != null) {
        if (json['requester'] != null && json['requester']['_id'] != userId) {
          userJson = json['requester'];
        } else if (json['recipient'] != null && json['recipient']['_id'] != userId) {
          userJson = json['recipient'];
        } else {
          userJson = json['recipient'] ?? json['requester'] ?? {};
        }
      } else {
        userJson = json['recipient'] ?? json['requester'] ?? {};
      }
      return Friend(
        id: (userJson['_id']?.toString() ?? userJson['id']?.toString() ?? ''),
        username: userJson['username']?.toString() ?? 'Desconocido',
        profilePictureUrl: userJson['avatar'] ?? userJson['profilePictureUrl'],
        isOnline: userJson['isOnline'] ?? false,
        lat: userJson['location']?['coordinates']?[1],
        lng: userJson['location']?['coordinates']?[0],
        distance: userJson['distance']?.toDouble(),
      );
    } else {
      // Si es un usuario directo
      return Friend(
        id: (json['_id']?.toString() ?? json['id']?.toString() ?? ''),
        username: json['username']?.toString() ?? 'Desconocido',
        profilePictureUrl: json['avatar'] ?? json['profilePictureUrl'],
        isOnline: json['isOnline'] ?? false,
        lat: json['location']?['coordinates']?[1],
        lng: json['location']?['coordinates']?[0],
        distance: json['distance']?.toDouble(),
      );
    }
  }
}