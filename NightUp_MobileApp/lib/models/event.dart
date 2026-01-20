import 'package:intl/intl.dart';
import '../utils/constants.dart';

class Event {
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'venue': venue,
      'description': description,
      'image': image,
      'price': price,
      'date': date.toIso8601String(),
      'tags': tags,
      'likes': likes,
      'participantsCount': participantsCount,
      'isLiked': isLiked,
      'participantsIds': participantsIds,
      'isJoined': isJoined,
      'location': {
        'coordinates': (lng != null && lat != null) ? [lng, lat] : [],
      },
    };
  }

  final String id;
  final String title;
  final String venue;
  final String description;
  final String image;
  final double price;
  final DateTime date;
  final List<String> tags;
  final int likes;
  final int participantsCount;
  final bool isLiked;
  final List<String> participantsIds;
  final bool isJoined;

  Event({
    required this.id,
    required this.title,
    required this.venue,
    required this.description,
    required this.image,
    required this.price,
    required this.date,
    required this.tags,
    required this.likes,
    required this.participantsCount,
    this.isLiked = false,
    this.participantsIds = const [],
    this.isJoined = false,
    this.lat,
    this.lng,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    if (json['location'] != null && json['location']['coordinates'] is List) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    }

    final rawId = json['_id'];

    String eventId;
    if (rawId is String) {
      eventId = rawId;
    } else if (rawId != null) {
      eventId = rawId.toString();
    } else {
      eventId = 'NO_ID';
    }

    List<String> participantsIds = [];
    if (json['participants'] is List) {
      participantsIds = (json['participants'] as List)
          .where((e) => e != null)
          .map((e) => e is String ? e : e.toString())
          .toList();
    }

    List<String> likedByIds = [];
    if (json['likedBy'] is List) {
      likedByIds = (json['likedBy'] as List)
          .where((e) => e != null)
          .map((e) => e is String ? e : e.toString())
          .toList();
    }

    return Event(
      id: eventId,
      title: json['name'] ?? 'Evento sin título',
      venue: _parseVenue(json['location']),
      description: json['description'] ?? '',
      image:
          json['image'] ??
          json['avatar'] ??
          json['mediaUrl'] ??
          json['photo'] ??
          '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(json['schedule']),
      tags: _parseTags(json),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      participantsCount: _getParticipantsCount(json),
      participantsIds: participantsIds,
      isLiked: false,
      isJoined: false,
      lat: lat,
      lng: lng,
    );
  }

  static String _parseVenue(dynamic location) {
    if (location is String) {
      return location;
    } else if (location is Map<String, dynamic>) {
      if (location['type'] == 'Point' && location['coordinates'] is List) {
        return '📍 Ver en mapa';
      }
      return location['name'] ??
          location['address'] ??
          'Ubicación no especificada';
    }
    return 'Ubicación no especificada';
  }

  static DateTime _parseDate(dynamic schedule) {
    if (schedule is String) {
      try {
        return DateTime.parse(schedule).toLocal();
      } catch (e) {
        return DateTime.now().add(const Duration(days: 1));
      }
    }
    return DateTime.now().add(const Duration(days: 1));
  }

  static List<String> _parseTags(Map<String, dynamic> json) {
    final tags = <String>[];
    if (json['category'] is String) {
      tags.add(json['category']);
    }

    return tags;
  }

  static int _getParticipantsCount(Map<String, dynamic> json) {
    if (json['participants'] is List) {
      return (json['participants'] as List).length;
    }
    return 0;
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Mañana ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM - HH:mm').format(date);
    }
  }

  String get displayPrice {
    return price > 0 ? '€${price.toStringAsFixed(2)}' : 'Gratis';
  }

  String get safeImageUrl {
    if (image.isEmpty) return '';

    if (image.startsWith('http')) {
      return image;
    }

    if (image.startsWith('/')) {
      return ApiConstants.baseUrl.replaceFirst('/api', '') + image;
    }

    return '${ApiConstants.baseUrl.replaceFirst('/api', '')}/$image';
  }

  Event copyWith({
    String? id,
    String? title,
    String? venue,
    String? description,
    String? image,
    double? price,
    DateTime? date,
    List<String>? tags,
    int? likes,
    int? participantsCount,
    bool? isLiked,
    List<String>? participantsIds,
    bool? isJoined,
    double? lat,
    double? lng,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      participantsCount: participantsCount ?? this.participantsCount,
      isLiked: isLiked ?? this.isLiked,
      participantsIds: participantsIds ?? this.participantsIds,
      isJoined: isJoined ?? this.isJoined,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, venue: $venue, date: $date, isLiked: $isLiked, isJoined: $isJoined}';
  }
}
