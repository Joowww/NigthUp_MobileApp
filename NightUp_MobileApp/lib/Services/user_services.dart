import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/user.dart';

class UserServices {
  final String baseUrl = 'http://localhost:3000/api/user';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<User>> fetchUsers() async {
    try {
      print('🔄 [USER SERVICE] Fetching users...');
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> usersData = data['users'] ?? [];
        
        List<User> users = usersData.map((dynamic item) => User.fromJson(item)).toList();
        print('✅ [USER SERVICE] Successfully fetched ${users.length} users');
        return users;
      } else {
        print('❌ [USER SERVICE] Failed to load users: ${response.statusCode}');
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [USER SERVICE] Error in fetchUsers: $e');
      throw Exception('Error loading users: $e');
    }
  }

  Future<User> fetchUserById(String id) async {
    try {
      print('🔄 [USER SERVICE] Fetching user by ID: $id');
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [USER SERVICE] Successfully fetched user: ${data['username']}');
        return User.fromJson(data);
      } else {
        print('❌ [USER SERVICE] Error loading user: ${response.statusCode}');
        throw Exception('Error loading user: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [USER SERVICE] Error in fetchUserById: $e');
      throw Exception('Error loading user: $e');
    }
  }

  Future<User> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      print('🔄 [USER SERVICE] Updating user profile: $userId');
      final response = await _client.patch(
        Uri.parse('$baseUrl/$userId'),
        body: json.encode(userData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = data['user'] ?? data;
        print('✅ [USER SERVICE] Successfully updated user profile');
        return User.fromJson(user);
      } else {
        print('❌ [USER SERVICE] Failed to update user: ${response.statusCode}');
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [USER SERVICE] Error in updateUserProfile: $e');
      throw Exception('Error updating user: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      print('🔄 [USER SERVICE] Fetching user stats...');
      final response = await _client.get(Uri.parse('$baseUrl/number-of-users'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [USER SERVICE] Successfully fetched user stats');
        return {'success': true, 'stats': data};
      } else {
        print('❌ [USER SERVICE] Failed to load stats: ${response.statusCode}');
        return {'success': false, 'message': 'Failed to load stats'};
      }
    } catch (e) {
      print('❌ [USER SERVICE] Error in getUserStats: $e');
      return {'success': false, 'message': 'Error loading stats: $e'};
    }
  }
}