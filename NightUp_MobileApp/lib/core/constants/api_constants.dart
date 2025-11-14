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
  static String joinEvent(String eventId) => '/event/$eventId/join';
  static String leaveEvent(String eventId) => '/event/$eventId/leave';
  
  // Business Endpoints
  static const String businesses = '/business';
  
  // Rating Endpoints
  static const String ratings = '/rating';
  static const String eventRatings = '/rating/event/{id}';
  
  // Tag Endpoints
  static const String tags = '/tag';
  
  // Interest Endpoints
  static const String interests = '/user-interest';
  static const String userInterests = '/user-interest';
  static String userInterestsByUserId(String userId) => '/user-interest/user/$userId';
  
  // Trust Endpoints
  static const String trust = '/user-trust';
  static const String trustRatings = '/user-trust/user/ratings';
  static String trustUserRatings(String userId) => '/user-trust/user/ratings/$userId';
  static String trustUserReceivedRatings(String userId) => '/user-trust/user/received/$userId';
  static String trustUserGivenRatings(String userId) => '/user-trust/user/given/$userId';
  static String updateTrust(String trustId) => '/user-trust/$trustId';
  static String deleteTrust(String trustId) => '/user-trust/$trustId';
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}