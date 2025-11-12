import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/user_trust.dart';

class UserTrustServices {
  final String baseUrl = 'http://localhost:3000/api/user-trust';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<UserTrust>> fetchTrustRatings() async {
    try {
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> ratingsData = data['ratings'] ?? [];
        
        List<UserTrust> ratings = ratingsData.map((dynamic item) => UserTrust.fromJson(item)).toList();
        return ratings;
      } else {
        throw Exception('Failed to load trust ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTrustRatings: $e');
      throw Exception('Error loading trust ratings: $e');
    }
  }

  Future<UserTrust> fetchTrustRatingById(String id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserTrust.fromJson(data);
      } else {
        throw Exception('Error loading trust rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTrustRatingById: $e');
      throw Exception('Error loading trust rating: $e');
    }
  }

  Future<List<UserTrust>> fetchTrustRatingsByUser(String userId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/ratings/$userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> ratingsData = jsonDecode(response.body);
        List<UserTrust> ratings = ratingsData.map((dynamic item) => UserTrust.fromJson(item)).toList();
        return ratings;
      } else {
        throw Exception('Failed to load user trust ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTrustRatingsByUser: $e');
      throw Exception('Error loading user trust ratings: $e');
    }
  }

  Future<List<UserTrust>> fetchTrustRatingsFromUser(String userId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/from/$userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> ratingsData = jsonDecode(response.body);
        List<UserTrust> ratings = ratingsData.map((dynamic item) => UserTrust.fromJson(item)).toList();
        return ratings;
      } else {
        throw Exception('Failed to load trust ratings from user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTrustRatingsFromUser: $e');
      throw Exception('Error loading trust ratings from user: $e');
    }
  }

  Future<UserTrust> createTrustRating(Map<String, dynamic> trustData) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(trustData),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserTrust.fromJson(data);
      } else {
        throw Exception('Failed to create trust rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createTrustRating: $e');
      throw Exception('Error creating trust rating: $e');
    }
  }

  Future<UserTrust> updateTrustRating(String ratingId, Map<String, dynamic> trustData) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/$ratingId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(trustData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserTrust.fromJson(data);
      } else {
        throw Exception('Failed to update trust rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateTrustRating: $e');
      throw Exception('Error updating trust rating: $e');
    }
  }

  Future<bool> deleteTrustRating(String ratingId) async {
    try {
      final response = await _client.delete(Uri.parse('$baseUrl/$ratingId'));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete trust rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteTrustRating: $e');
      throw Exception('Error deleting trust rating: $e');
    }
  }

  Future<Map<String, dynamic>> getUserTrustStats(String userId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/stats/$userId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {'success': true, 'stats': data};
      } else {
        return {'success': false, 'message': 'Failed to load user trust stats'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error loading user trust stats: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserTrustSummary(String userId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/summary/$userId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {'success': true, 'summary': data};
      } else {
        return {'success': false, 'message': 'Failed to load user trust summary'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error loading user trust summary: $e'};
    }
  }

  Future<List<dynamic>> getAllUsersTrustSummary() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/admin/all-summaries'));
      
      if (response.statusCode == 200) {
        final List<dynamic> summaries = jsonDecode(response.body);
        return summaries;
      } else {
        throw Exception('Failed to load all users trust summaries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllUsersTrustSummary: $e');
      throw Exception('Error loading all users trust summaries: $e');
    }
  }

  Future<bool> hasUserRated(String ratedUserId, String context) async {
    try {
      // Esta funcionalidad requiere lógica adicional en el backend o cliente
      // Por ahora devolvemos false
      return false;
    } catch (e) {
      print('Error in hasUserRated: $e');
      return false;
    }
  }
}