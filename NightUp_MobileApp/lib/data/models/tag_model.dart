import 'package:flutter/material.dart';

class TagModel {
  final String id; // MongoDB _id como String
  final String name;
  final String? description;
  final String color; // Requerido en el backend con default
  final List<String> events; // Nuevo campo del backend
  final bool active; // Nuevo campo del backend
  final DateTime createdAt;
  final DateTime updatedAt;

  TagModel({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.events,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#3b82f6',
      events: json['events'] != null 
          ? List<String>.from(json['events']) 
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
      'events': events,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Color get colorValue {
    if (color.isNotEmpty) {
      try {
        return Color(int.parse(color.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }
}