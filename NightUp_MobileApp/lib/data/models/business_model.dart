class BusinessModel {
  final String id; // MongoDB _id como String
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? description; // No existe en backend, mantener para compatibilidad
  final List<String> managers; // Cambio: managerIds -> managers
  final List<String> events; // Cambio: eventIds -> events
  final bool active;

  BusinessModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.description,
    required this.managers,
    required this.events,
    required this.active,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      description: json['description'],
      managers: json['managers'] != null 
          ? List<String>.from(json['managers']) 
          : [],
      events: json['events'] != null 
          ? List<String>.from(json['events']) 
          : [],
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'description': description,
      'managers': managers,
      'events': events,
      'active': active,
    };
  }
}