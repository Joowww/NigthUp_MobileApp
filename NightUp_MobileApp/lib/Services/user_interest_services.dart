import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/user_interest.dart';

class UserInterestServices {
  final String baseUrl = 'http://localhost:3000/api/user-interest';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<UserInterest>> fetchUserInterests() async {
    try {
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> interestsData = data['interests'] ?? [];
        
        List<UserInterest> interests = interestsData.map((dynamic item) => UserInterest.fromJson(item)).toList();
        return interests;
      } else {
        throw Exception('Failed to load user interests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserInterests: $e');
      throw Exception('Error loading user interests: $e');
    }
  }

  Future<UserInterest> fetchUserInterestById(String id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserInterest.fromJson(data);
      } else {
        throw Exception('Error loading user interest: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserInterestById: $e');
      throw Exception('Error loading user interest: $e');
    }
  }

  Future<List<UserInterest>> fetchUserInterestsByUser(String userId) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/user/$userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> interestsData = jsonDecode(response.body);
        List<UserInterest> interests = interestsData.map((dynamic item) => UserInterest.fromJson(item)).toList();
        return interests;
      } else {
        throw Exception('Failed to load user interests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserInterestsByUser: $e');
      throw Exception('Error loading user interests: $e');
    }
  }

  Future<UserInterest> createUserInterest(Map<String, dynamic> interestData) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(interestData),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserInterest.fromJson(data);
      } else {
        throw Exception('Failed to create user interest: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createUserInterest: $e');
      throw Exception('Error creating user interest: $e');
    }
  }

  Future<UserInterest> updateUserInterest(String interestId, Map<String, dynamic> interestData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/$interestId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(interestData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserInterest.fromJson(data);
      } else {
        throw Exception('Failed to update user interest: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateUserInterest: $e');
      throw Exception('Error updating user interest: $e');
    }
  }

  Future<Map<String, dynamic>> getUserInterestStats() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/stats'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {'success': true, 'stats': data};
      } else {
        return {'success': false, 'message': 'Failed to load user interest stats'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error loading user interest stats: $e'};
    }
  }
}