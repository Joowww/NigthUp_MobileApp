class Friend {
  final String id;
  final String username;
  final String? profilePictureUrl;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final double? distance;

  Friend({
    required this.id,
    required this.username,
    this.profilePictureUrl,
    this.isOnline = false,
    this.lat,
    this.lng,
    this.distance,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      profilePictureUrl: json['profilePictureUrl'],
      isOnline: json['isOnline'] ?? false,
      lat: json['location']?['coordinates']?[1],
      lng: json['location']?['coordinates']?[0],
      distance: json['distance']?.toDouble(),
    );
  }
}