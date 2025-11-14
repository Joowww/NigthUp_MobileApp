class ApiConstants {
  // Cambia esto por tu URL del backend
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth Endpoints
  static const String login = '/user/auth/login';
  static const String register = '/user';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/user/auth/refresh';
  
  // User Endpoints
  static const String users = '/user';
  static const String profile = '/user/me';
  static const String updateProfile = '/user/me';
  static const String changePassword = '/user/change-password';
  
  // Event Endpoints
  static const String events = '/event';
  static const String myEvents = '/event/my-events';
  static const String joinEvent = '/event/{id}/join';
  static const String leaveEvent = '/event/{id}/leave';
  
  // Business Endpoints
  static const String businesses = '/businesses';
  
  // Rating Endpoints
  static const String ratings = '/ratings';
  static const String eventRatings = '/ratings/event/{id}';
  
  // Tag Endpoints
  static const String tags = '/tags';
  
  // Interest Endpoints
  static const String interests = '/interests';
  static const String userInterests = '/user-interests';
  
  // Trust Endpoints
  static const String trust = '/trust';
  static const String trustRatings = '/trust/ratings';
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}