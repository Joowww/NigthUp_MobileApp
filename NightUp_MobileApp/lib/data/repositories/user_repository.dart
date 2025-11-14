import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getUsers({int skip = 0, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.users}?skip=$skip&limit=$limit',
      );
      
      final users = (response.data['users'] ?? [])
          .map<UserModel>((json) => UserModel.fromJson(json))
          .toList();
      
      final pagination = response.data['pagination'] ?? {};
      
      return {
        'users': users,
        'pagination': pagination,
        'hasMore': pagination['hasMore'] ?? false,
        'total': pagination['total'] ?? users.length,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _apiService.get('${ApiConstants.users}/number-of-users');
      return response.data;
    } on DioException catch (e) {
      print('Error loading user stats: ${_handleError(e)}');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'newCount': 0,
      };
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.users}/$id');
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? birthday,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;
      if (birthday != null) data['birthday'] = birthday;

      final response = await _apiService.patch(
        ApiConstants.updateProfile,
        data: data,
      );
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Error desconocido';
      }
      return 'Error del servidor';
    }
    return 'Error de conexión';
  }
}