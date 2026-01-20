import 'user.dart';
import '../utils/constants.dart';

class Post {
  final String id;
  final String? mediaUrl;
  final int likes;

  final User? user;
  final String? caption;
  final String? location;
  final int comments;
  final bool isVideo;
  final bool isLiked;
  final Map<String, dynamic>? music;
  final String? filterColor;

  final String? title;
  final String? venue;
  final String? price;
  final String? eventId;

  Post({
    required this.id,
    this.mediaUrl,
    this.likes = 0,
    this.user,
    this.caption,
    this.location,
    this.comments = 0,
    this.isVideo = false,
    this.isLiked = false,
    this.music,
    this.filterColor,
    this.title,
    this.venue,
    this.price,
    this.eventId,
  });

  Post copyWith({int? likes, int? comments, bool? isLiked}) {
    return Post(
      id: id,
      mediaUrl: mediaUrl,
      likes: likes ?? this.likes,
      user: user,
      caption: caption,
      location: location,
      comments: comments ?? this.comments,
      isVideo: isVideo,
      isLiked: isLiked ?? this.isLiked,
      music: music,
      filterColor: filterColor,
      title: title,
      venue: venue,
      price: price,
      eventId: eventId,
    );
  }

  String get safeMediaUrl {
    if (mediaUrl == null || mediaUrl!.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1514525253361-bee8a4874093?w=800';
    }
    final String url = mediaUrl!.trim();

    if (url.startsWith('http')) {
      return url;
    }

    if (url.startsWith('/')) {
      return ApiConstants.baseUrl.replaceFirst('/api', '') + url;
    }

    return '${ApiConstants.baseUrl.replaceFirst('/api', '')}/$url';
  }

  factory Post.fromDiscoverJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] as String? ?? '0',
      mediaUrl: json['mediaUrl'] as String?,
      title: json['title'] as String?,
      venue: json['venue'] as String?,
      price: json['price'] != null && (json['price'] as num) > 0
          ? '\$${json['price']}'
          : 'Entrada Gratis',
      eventId: json['_id'] as String?,
      likes: json['likesCount'] as int? ?? 0,
    );
  }

  factory Post.fromFriendPostJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] as String? ?? '0',
      mediaUrl: json['mediaUrl'] as String?,
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      isVideo: json['isVideo'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      music: json['music'] != null
          ? Map<String, dynamic>.from(json['music'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      likes: json['likesCount'] as int? ?? 0,
      comments: json['commentCount'] as int? ?? 0,
      filterColor: json['filterColor'] as String?,
    );
  }
}
