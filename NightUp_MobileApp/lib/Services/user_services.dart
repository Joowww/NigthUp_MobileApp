import 'package:NightUp_MobileApp/Models/user.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';

class UserServices {
  final String baseUrl = 'http://localhost:3000/api/user';
  final AuthInterceptor _client = Get.put(AuthInterceptor());
  UserServices();

  Future<List<User>> fetchUsers() async {
    final response = await _client.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<User> users =
          body.map((dynamic item) => User.fromJson(item)).toList();
      return users;
    } else {
      throw Exception('Failed to load users');
    }
  }
  Future<User> fetchUserById(String id) async {
    try {
      
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Error al cargar el usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserById: $e');
      throw Exception('Error al cargar el usuario: $e');
    }
  }


  Future<User> updateUser(String id, User user) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/$id'),
        body: jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Error al actualizar el usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateUser: $e');
      throw Exception('Error al actualizar el usuario: $e');
    }
  }
}