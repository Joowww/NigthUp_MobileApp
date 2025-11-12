import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/rating.dart';

class RatingServices {
  final String baseUrl = 'http://localhost:3000/api/rating';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<Rating>> fetchRatings() async {
    try {
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> ratingsData = data['ratings'] ?? [];
        
        List<Rating> ratings = ratingsData.map((dynamic item) => Rating.fromJson(item)).toList();
        return ratings;
      } else {
        throw Exception('Failed to load ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchRatings: $e');
      throw Exception('Error loading ratings: $e');
    }
  }

  Future<Rating> fetchRatingById(String id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Rating.fromJson(data);
      } else {
        throw Exception('Error loading rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchRatingById: $e');
      throw Exception('Error loading rating: $e');
    }
  }

  Future<List<Rating>> fetchRatingsByEvent(String eventId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/event/$eventId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> ratingsData = jsonDecode(response.body);
        List<Rating> ratings = ratingsData.map((dynamic item) => Rating.fromJson(item)).toList();
        return ratings;
      } else {
        throw Exception('Failed to load event ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchRatingsByEvent: $e');
      throw Exception('Error loading event ratings: $e');
    }
  }

  Future<List<Rating>> fetchRatingsByUser(String username) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/$username'));
      
      if (response.statusCode == 200) {
        final List<dynamic> ratingsData = jsonDecode(response.body);
        List<Rating> ratings = ratingsData.map((dynamic item) => Rating.fromJson(item)).toList();
        return ratings;
      } else {
        throw Exception('Failed to load user ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchRatingsByUser: $e');
      throw Exception('Error loading user ratings: $e');
    }
  }

  Future<Rating> createRating(Map<String, dynamic> ratingData) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ratingData),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Rating.fromJson(data);
      } else {
        throw Exception('Failed to create rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createRating: $e');
      throw Exception('Error creating rating: $e');
    }
  }

  Future<Rating> updateRating(String ratingId, Map<String, dynamic> ratingData) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/$ratingId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ratingData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Rating.fromJson(data);
      } else {
        throw Exception('Failed to update rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateRating: $e');
      throw Exception('Error updating rating: $e');
    }
  }

  Future<bool> deleteRating(String ratingId) async {
    try {
      final response = await _client.delete(Uri.parse('$baseUrl/$ratingId'));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteRating: $e');
      throw Exception('Error deleting rating: $e');
    }
  }

  Future<Map<String, dynamic>> getEventRatingStats(String eventId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/event/$eventId/stats'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {'success': true, 'stats': data};
      } else {
        return {'success': false, 'message': 'Failed to load rating stats'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error loading rating stats: $e'};
    }
  }

  Future<Rating?> getUserEventRating(String username, String eventId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/$username/event/$eventId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Rating.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load user event rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserEventRating: $e');
      throw Exception('Error loading user event rating: $e');
    }
  }
}