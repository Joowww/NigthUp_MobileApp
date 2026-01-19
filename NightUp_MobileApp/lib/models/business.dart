import 'package:intl/intl.dart';
import '../utils/constants.dart';

class Business {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String avatar;
  final List<String> events;
  final List<String> managers;
  final bool active;
  final double? lat;
  final double? lng;

  Business({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.avatar,
    required this.events,
    required this.managers,
    required this.active,
    this.lat,
    this.lng,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    if (json['location'] != null && json['location']['coordinates'] is List) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2) {
        lng = coords[0]?.toDouble();
        lat = coords[1]?.toDouble();
      }
    }

    return Business(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? 'Business',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      avatar:
          json['avatar'] ??
          json['image'] ??
          json['profilePicture'] ??
          json['logo'] ??
          '',
      events: json['events'] != null
          ? List<String>.from(json['events'].map((e) => e.toString()))
          : [],
      managers: json['managers'] != null
          ? List<String>.from(json['managers'].map((m) => m.toString()))
          : [],
      active: json['active'] ?? true,
      lat: lat,
      lng: lng,
    );
  }

  String? get safeImageUrl {
    if (avatar.isEmpty) return null;

    if (avatar.startsWith('http')) {
      return avatar;
    }

    if (avatar.startsWith('/')) {
      return ApiConstants.baseUrl.replaceFirst('/api', '') + avatar;
    }

    return '${ApiConstants.baseUrl.replaceFirst('/api', '')}/$avatar';
  }

  String get displayAddress => address ?? 'No address provided';
  String get displayContact => phone ?? email ?? 'No contact info';
  String get displayHours => '9 PM - 4 AM';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'events': events,
      'managers': managers,
      'active': active,
      'lat': lat,
      'lng': lng,
    };
  }
}
