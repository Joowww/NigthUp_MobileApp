class EventModel {
  final String id; // Cambio de int a String para MongoDB _id
  final String name;
  final String description;
  final DateTime schedule; // Cambio de String a DateTime
  final String location;
  final String category;
  final int capacity;
  final double price;
  final List<String> participants; // Array de IDs de usuarios participantes
  final bool active;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.schedule,
    required this.location,
    required this.category,
    required this.capacity,
    required this.price,
    this.participants = const [],
    this.active = true,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse participants - pueden ser strings o objetos
    List<String> participantsList = [];
    if (json['participants'] != null) {
      try {
        final participants = json['participants'] as List;
        for (var participant in participants) {
          if (participant is String) {
            participantsList.add(participant);
          } else if (participant is Map<String, dynamic>) {
            // Si es un objeto, extraer el ID
            participantsList.add(participant['_id'] ?? participant['id'] ?? '');
          }
        }
      } catch (e) {
        print('Error parsing participants: $e');
        // Si hay error, usar lista vacía
        participantsList = [];
      }
    }

    // Parse schedule con manejo de errores
    DateTime scheduleDate = DateTime.now();
    if (json['schedule'] != null) {
      try {
        scheduleDate = DateTime.parse(json['schedule']);
      } catch (e) {
        print('Error parsing schedule date: ${json['schedule']} - $e');
        scheduleDate = DateTime.now();
      }
    }

    // Parse createdAt con manejo de errores
    DateTime createdAtDate = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        createdAtDate = DateTime.parse(json['createdAt']);
      } catch (e) {
        print('Error parsing createdAt date: ${json['createdAt']} - $e');
        createdAtDate = DateTime.now();
      }
    }

    // Parse updatedAt con manejo de errores
    DateTime updatedAtDate = DateTime.now();
    if (json['updatedAt'] != null) {
      try {
        updatedAtDate = DateTime.parse(json['updatedAt']);
      } catch (e) {
        print('Error parsing updatedAt date: ${json['updatedAt']} - $e');
        updatedAtDate = DateTime.now();
      }
    }

    return EventModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Evento sin nombre',
      description: json['description'] ?? 'Descripción no disponible',
      schedule: scheduleDate,
      location: json['location'] ?? 'Ubicación no especificada',
      category: json['category'] ?? 'general',
      capacity: json['capacity'] ?? 100, // Valor por defecto
      price: (json['price'] ?? 0).toDouble(),
      participants: participantsList,
      active: json['active'] ?? true,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'schedule': schedule.toIso8601String(),
      'location': location,
      'category': category,
      'capacity': capacity,
      'price': price,
      'participants': participants,
      'active': active,
      'image_url': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Getters útiles
  double get occupancyPercentage => capacity > 0 ? (participants.length / capacity) * 100 : 0;
  bool get isFull => participants.length >= capacity;
  int get currentParticipants => participants.length;
  
  EventModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? schedule,
    String? location,
    String? category,
    int? capacity,
    double? price,
    List<String>? participants,
    bool? active,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      category: category ?? this.category,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      participants: participants ?? this.participants,
      active: active ?? this.active,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}