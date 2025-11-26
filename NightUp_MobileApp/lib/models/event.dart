import 'package:intl/intl.dart';

class Event {
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
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      title: json['name'] ?? 'Evento sin título',
      venue: _parseVenue(json['location']),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(json['schedule']),
      tags: _parseTags(json),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      participantsCount: _getParticipantsCount(json),
    );
  }

  static String _parseVenue(dynamic location) {
    if (location is String) {
      return location;
    } else if (location is Map<String, dynamic>) {
      return location['name'] ?? location['address'] ?? 'Ubicación no especificada';
    }
    return 'Ubicación no especificada';
  }

  static DateTime _parseDate(dynamic schedule) {
    if (schedule is String) {
      try {
        return DateTime.parse(schedule).toLocal();
      } catch (e) {
        print('Error parsing date: $e');
        return DateTime.now().add(const Duration(days: 1));
      }
    }
    return DateTime.now().add(const Duration(days: 1));
  }

  static List<String> _parseTags(Map<String, dynamic> json) {
    final tags = <String>[];
    
    // Añadir categoría como tag principal
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

  // Getters para la UI
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
    // Si no hay imagen, devolver string vacío para que ImageWithFallback use el asset por defecto
    if (image.isEmpty) {
      return '';
    }
    
    // Si la imagen es una ruta relativa (como '/default-images/default-event.jpg')
    // construir URL completa con tu base URL
    if (image.startsWith('/')) {
      // CONFIGURA AQUÍ TU DOMINIO REAL DEL BACKEND
      const baseUrl = 'http://localhost:3000'; // ⚠️ CAMBIA ESTO POR TU DOMINIO REAL
      return '$baseUrl$image';
    }
    
    // Si ya es una URL completa, usarla directamente
    return image;
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, venue: $venue, date: $date}';
  }
}