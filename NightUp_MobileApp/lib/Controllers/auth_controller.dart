import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user.dart';
import '../Interceptor/auth_interceptor.dart';

class AuthController extends GetxController {
  final String apiUrl = 'http://localhost:3000/api';
  var isLoggedIn = false.obs;
  var currentUser = Rxn<User>();
  String? token;
  String? refreshToken;

  @override
  void onInit() {
    super.onInit();
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedRefreshToken = prefs.getString('refreshToken');
      final storedUser = prefs.getString('user');

      if (storedToken != null && storedUser != null) {
        token = storedToken;
        refreshToken = storedRefreshToken;
        currentUser.value = User.fromJson(json.decode(storedUser));
        isLoggedIn.value = true;
        print('✅ [AUTH] Stored auth data loaded successfully');
      }
    } catch (e) {
      print('❌ [AUTH] Error loading stored auth: $e');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔄 [AUTH] Attempting login for user: $username');

      final response = await http.post(
        Uri.parse('$apiUrl/user/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('📨 [AUTH] Login Response status: ${response.statusCode}');
      print('📨 [AUTH] Login Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['user'] == null) {
          return {
            'success': false,
            'message': 'Invalid response from server'
          };
        }

        final user = User.fromJson(data['user']);
        
        await _storeAuthData(
          data['token'],
          data['refreshToken'],
          json.encode(data['user']),
        );

        currentUser.value = user;
        token = data['token'];
        refreshToken = data['refreshToken'];
        isLoggedIn.value = true;

        print('✅ [AUTH] Login successful for user: ${user.username}');
        return {'success': true, 'message': 'Login exitoso'};
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Error en el login - Código: ${response.statusCode}';
        print('❌ [AUTH] Login failed: $errorMessage');
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      print('❌ [AUTH] Login error: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  Future<Map<String, dynamic>> register(User newUser, String password) async {
    try {
      print('🔄 [AUTH] Attempting registration for user: ${newUser.username}');

      final response = await http.post(
        Uri.parse('$apiUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': newUser.username,
          'email': newUser.email,
          'password': password,
          'birthday': newUser.birthday,
          'role': 'user'
        }),
      );

      print('📨 [AUTH] Register response status: ${response.statusCode}');
      print('📨 [AUTH] Register response body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ [AUTH] Registration successful for user: ${newUser.username}');
        return {'success': true, 'message': 'Usuario registrado exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Error en el registro - Código: ${response.statusCode}';
        print('❌ [AUTH] Registration failed: $errorMessage');
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      print('❌ [AUTH] Registration error: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      await prefs.remove('user');
      
      isLoggedIn.value = false;
      currentUser.value = null;
      token = null;
      refreshToken = null;
      
      print('✅ [AUTH] Logout successful');
    } catch (e) {
      print('❌ [AUTH] Logout error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteCurrentUser() async {
    try {
      if (currentUser.value == null || token == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/user/hard/${currentUser.value!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
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

  Future<void> _storeAuthData(String token, String refreshToken, String userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('user', userData);
      print('✅ [AUTH] Auth data stored successfully');
    } catch (e) {
      print('❌ [AUTH] Error storing auth data: $e');
    }
  }

  bool get isAdmin => currentUser.value?.role == 'admin';
  bool get isManager => currentUser.value?.role == 'manager' || isAdmin;
  bool get isRegularUser => currentUser.value?.role == 'user';

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Contraseña cambiada exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al cambiar la contraseña'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  Future<Map<String, dynamic>> changeEmail(String newEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/user/change-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'newEmail': newEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Actualizar el usuario actual
        if (currentUser.value != null) {
          currentUser.value = User.fromJson({
            ...currentUser.value!.toJson(),
            'email': newEmail,
          });
        }
        return {'success': true, 'message': 'Email cambiado exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al cambiar el email'
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