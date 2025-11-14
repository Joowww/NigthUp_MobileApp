import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../models/business_model.dart';

class BusinessRepository {
  final ApiService _apiService = ApiService();

  Future<List<BusinessModel>> getBusinesses() async {
    try {
      final response = await _apiService.get(ApiConstants.businesses);
      
      // Handle different response structures based on your backend
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final businesses = data['businesses'] ?? data['data'] ?? [];
        return (businesses as List).map((json) => BusinessModel.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => BusinessModel.fromJson(json)).toList();
      }
      
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BusinessModel> getBusinessById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.businesses}/$id');
      return BusinessModel.fromJson(response.data['data'] ?? response.data);
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