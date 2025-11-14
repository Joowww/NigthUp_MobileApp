import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../models/interest_model.dart';

class InterestRepository {
  final ApiService _apiService = ApiService();

  Future<List<InterestModel>> getInterests() async {
    try {
      final response = await _apiService.get(ApiConstants.interests);
      final data = response.data['data'] ?? response.data['interests'] ?? response.data;
      if (data is List) {
        return data.map((json) => InterestModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<InterestModel>> getUserInterests() async {
    try {
      final response = await _apiService.get(ApiConstants.userInterests);
      final data = response.data['data'] ?? response.data['interests'] ?? response.data;
      if (data is List) {
        return data.map((json) => InterestModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addUserInterest(String interestId) async {
    try {
      // Primero, verificar que el interés existe
      final allInterests = await getInterests();
      final interestExists = allInterests.any((interest) => interest.id == interestId);
      
      if (!interestExists) {
        throw 'El interés seleccionado no existe. Recarga la página e inténtalo de nuevo.';
      }
      
      await _apiService.post(
        ApiConstants.userInterests,
        data: {
          'interest': interestId,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw 'La funcionalidad de intereses no está disponible en este momento';
      }
      if (e.response?.statusCode == 401) {
        throw 'Necesitas estar autenticado para añadir intereses. Por favor, vuelve a iniciar sesión.';
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message']?.toString() ?? '';
        if (message.contains('already exists') || message.contains('ya existe')) {
          throw 'Ya tienes este interés en tu perfil';
        }
        throw 'Datos inválidos. Verifica la información e inténtalo de nuevo.';
      }
      if (e.response?.statusCode == 500) {
        final details = e.response?.data?['details']?.toString() ?? '';
        final message = e.response?.data?['message']?.toString() ?? '';
        if (details.contains('name') && details.contains('required')) {
          throw 'Error del servidor. El interés existe pero hubo un problema al añadirlo a tu perfil.';
        }
        if (message.contains('interest') && message.contains('not found')) {
          throw 'El interés seleccionado no existe. Recarga la página e inténtalo de nuevo.';
        }
        throw 'Error interno del servidor. Inténtalo de nuevo más tarde.';
      }
      throw _handleError(e);
    }
  }

  Future<void> removeUserInterest(String interestId) async {
    try {
      await _apiService.delete(
        '${ApiConstants.userInterests}/$interestId',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw 'La funcionalidad de intereses no está disponible en este momento';
      }
      throw _handleError(e);
    }
  }

  Future<InterestModel> createInterest({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.interests,
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );
      
      final data = response.data['data'] ?? response.data;
      return InterestModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw 'La funcionalidad de crear intereses no está disponible en este momento';
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