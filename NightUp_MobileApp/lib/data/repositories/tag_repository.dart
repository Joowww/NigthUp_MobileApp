import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../models/tag_model.dart';

class TagRepository {
  final ApiService _apiService = ApiService();

  Future<List<TagModel>> getTags({int skip = 0, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.tags}?skip=$skip&limit=$limit',
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final tags = data['tags'] ?? data['data'] ?? [];
        return (tags as List).map((json) => TagModel.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => TagModel.fromJson(json)).toList();
      }
      
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TagModel> getTagById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.tags}/$id');
      return TagModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TagModel> createTag({
    required String name,
    required String color,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.tags,
        data: {
          'name': name,
          'color': color,
          if (description != null) 'description': description,
        },
      );
      
      final data = response.data['data'] ?? response.data;
      return TagModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw 'La funcionalidad de crear tags no está disponible en este momento';
      }
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