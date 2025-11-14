import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../models/auth_response_model.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // Guardar token y usuario
      if (authResponse.token != null) {
        await _storage.saveToken(authResponse.token!);
      }
      await _storage.saveUser(authResponse.user.toJson());
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
    String? birthday,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (birthday != null) 'birthday': birthday,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // Para registro, solo guardamos el usuario ya que no hay token
      // El usuario deberá hacer login después del registro
      await _storage.saveUser(authResponse.user.toJson());
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
    } catch (e) {
      // Continuar incluso si falla
    } finally {
      await _storage.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Error desconocido';
      }
      return 'Error del servidor';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Tiempo de conexión agotado';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de respuesta agotado';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Error de conexión. Verifica tu internet';
    }
    return 'Error de conexión';
  }
}