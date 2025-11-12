class UserInterest {
  final String id;
  final String name;
  final String? description;
  final String color;
  final List<String> users;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserInterest({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.users,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory UserInterest.fromJson(Map<String, dynamic> json) {
    return UserInterest(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#8b5cf6',
      users: List<String>.from(json['users']?.map((x) => x.toString()) ?? []),
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color,
    };
  }
}