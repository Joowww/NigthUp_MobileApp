// lib/models/post.dart
import 'user.dart';

class Post {
  final String id;
  // Comunes
  final String? mediaUrl; 
  final int likes;
  
  // Específico de Friends (Posts de Usuario)
  final User? user;
  final String? caption;
  final String? location;
  final int comments;
  
  // Específico de Discover (Eventos)
  final String? title; 
  final String? venue; 
  final String? price; 
  final String? eventId; // Usaremos String si el _id de Mongo es el ID

  Post({
    required this.id,
    this.mediaUrl,
    this.likes = 0,
    this.user,
    this.caption,
    this.location,
    this.comments = 0,
    this.title,
    this.venue,
    this.price,
    this.eventId,
  });

  // Constructor para posts de Discover (Eventos)
  factory Post.fromDiscoverJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] as String? ?? '0',
      mediaUrl: json['mediaUrl'] as String?, 
      title: json['title'] as String?,
      venue: json['venue'] as String?, 
      // Si el precio es 0, lo muestra como Free Entry
      price: json['price'] != null && (json['price'] as num) > 0 ? '\$${json['price']}' : 'Free Entry', 
      eventId: json['_id'] as String?, 
      likes: json['likes'] as int? ?? 0,
    );
  }

  // Constructor para posts de Friends
  factory Post.fromFriendPostJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] as String? ?? '0',
      mediaUrl: json['mediaUrl'] as String?,
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      // Usa el fromJson que ahora tiene profilePictureUrl
      user: json['user'] != null ? User.fromJson(json['user']) : null, 
      likes: json['likes'] as int? ?? 0,
      comments: json['commentCount'] as int? ?? 0,
    );
  }
}