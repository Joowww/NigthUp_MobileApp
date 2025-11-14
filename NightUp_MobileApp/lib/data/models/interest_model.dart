class InterestModel {
  final String id; // MongoDB _id como String
  final String name;
  final String? description;
  final String color; // Nuevo campo del backend
  final List<String> users; // Nuevo campo del backend
  final bool active; // Nuevo campo del backend
  final DateTime createdAt;
  final DateTime updatedAt;

  InterestModel({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.users,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InterestModel.fromJson(Map<String, dynamic> json) {
    return InterestModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#8b5cf6',
      users: json['users'] != null 
          ? List<String>.from(json['users']) 
          : [],
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'color': color,
      'users': users,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}