class Business {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final List<String> events;
  final List<String> managers;
  final bool active;

  Business({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.events,
    required this.managers,
    required this.active,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      events: List<String>.from(json['events']?.map((x) => x.toString()) ?? []),
      managers: List<String>.from(json['managers']?.map((x) => x.toString()) ?? []),
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}