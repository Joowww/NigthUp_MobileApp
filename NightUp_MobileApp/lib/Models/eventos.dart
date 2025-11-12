class Evento {
  final String id;
  final String name;
  final String schedule;
  final String location;
  final String description;
  final String category;
  final int capacity;
  final double price;
  final List<String> participants;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Evento({
    required this.id,
    required this.name,
    required this.schedule,
    required this.location,
    required this.description,
    required this.category,
    required this.capacity,
    required this.price,
    required this.participants,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      schedule: json['schedule'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      participants: List<String>.from(json['participants']?.map((x) => x.toString()) ?? []),
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'schedule': schedule,
      'location': location,
      'description': description,
      'category': category,
      'capacity': capacity,
      'price': price,
    };
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(schedule).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return schedule;
    }
  }

  String get formattedPrice {
    return '€$price';
  }

  String get participantsCount {
    return '${participants.length}/$capacity';
  }

  bool get isFull => participants.length >= capacity;
  int get availableSpots => capacity - participants.length;
}