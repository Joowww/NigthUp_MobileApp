import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../Models/user.dart';

class AuthController extends GetxController {
  final String apiUrl = 'http://localhost:3000/api';
  var isLoggedIn = false.obs;
  var currentUser = Rxn<User>();
  String? token;
  String? refreshToken;

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/user/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['User'];
        
        currentUser.value = User.fromJson({
          ...userData,
          'token': data['token'],
          'refreshToken': data['refreshToken'],
        });
        
        token = data['token'];
        refreshToken = data['refreshToken'];
        isLoggedIn.value = true;
        print('token $token refrehtoken, $refreshToken');
        
        return {'success': true, 'message': 'Login exitoso'};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false, 
          'message': errorData['error'] ?? 'Error en el login - Código: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error en login: $e');
      return {
        'success': false, 
        'message': 'Error de conexión: $e'
      };
    }
  }

  Future<Map<String, dynamic>> register(User newUser) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(newUser.toJson()),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Usuario registrado exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false, 
          'message': errorData['error'] ?? 'Error en el registro - Código: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error en registro: $e');
      return {
        'success': false, 
        'message': 'Error de conexión: $e'
      };
    }
  }

  void logout() {
    isLoggedIn.value = false;
    currentUser.value = null;
    token = null;
  }

  Future<Map<String, dynamic>> deleteCurrentUser() async {
    try {
      if (currentUser.value == null || token == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/user/${currentUser.value!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        logout();
        return {'success': true, 'message': 'Usuario eliminado exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false, 
          'message': errorData['error'] ?? 'Error al eliminar el usuario'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'message': 'Error de conexión: $e'
      };
    }
  }
}