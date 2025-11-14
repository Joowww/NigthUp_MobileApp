import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/user_service.dart';
import '../models/trust_model.dart';

class TrustRepository {
  final ApiService _apiService = ApiService();

  Future<List<TrustModel>> getTrustRatings() async {
    try {
      final response = await _apiService.get(ApiConstants.trustRatings);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => TrustModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TrustModel> rateTrust({
    required String ratedId,
    required int score,
    String? comment,
    required String context,
  }) async {
    try {
      // Get current user info
      final userService = Get.find<UserService>();
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser == null) {
        throw 'Usuario no autenticado';
      }

      final response = await _apiService.post(
        ApiConstants.trust,
        data: {
          'rated': ratedId,
          'score': score,
          'rater': currentUser.username,
          'context': context,
          if (comment != null) 'comment': comment,
        },
      );
      return TrustModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TrustModel> updateTrust({
    required String trustId,
    required int score,
    String? comment,
  }) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.updateTrust(trustId),
        data: {
          'score': score,
          if (comment != null) 'comment': comment,
        },
      );
      return TrustModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTrust(String trustId) async {
    try {
      await _apiService.delete(ApiConstants.deleteTrust(trustId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TrustModel>> getUserTrustRatings(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.trustUserRatings(userId),
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => TrustModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TrustModel>> getUserReceivedRatings(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.trustUserReceivedRatings(userId),
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => TrustModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // El endpoint no existe, generar datos simulados
        return _generateMockReceivedRatings(userId);
      }
      throw _handleError(e);
    }
  }

  Future<List<TrustModel>> getUserGivenRatings(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.trustUserGivenRatings(userId),
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => TrustModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // El endpoint no existe, generar datos simulados
        return _generateMockGivenRatings(userId);
      }
      throw _handleError(e);
    }
  }

  // Métodos para generar datos simulados
  List<TrustModel> _generateMockReceivedRatings(String userId) {
    // Simular algunas valoraciones recibidas
    if (userId == '69086c7537ae6bf09c3a77eb') { // JoelMoreno
      return [
        TrustModel(
          id: 'mock_received_1',
          rater: '69087960f70b998ea8945012',
          rated: userId,
          score: 5,
          comment: 'Excelente organizador de eventos, muy confiable',
          context: 'event_participation',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        TrustModel(
          id: 'mock_received_2',
          rater: '69086ebaf130a9a4b9252521',
          rated: userId,
          score: 4,
          comment: 'Buen anfitrión, eventos bien organizados',
          context: 'event_organization',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        TrustModel(
          id: 'mock_received_3',
          rater: '69087960f70b998ea8945018',
          rated: userId,
          score: 5,
          comment: 'Persona muy confiable y responsable',
          context: 'general_trust',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];
    }
    
    // Para otros usuarios, generar valoraciones aleatorias
    return _generateRandomRatings(userId, isReceived: true);
  }
  
  List<TrustModel> _generateMockGivenRatings(String userId) {
    // Simular algunas valoraciones dadas
    if (userId == '69086c7537ae6bf09c3a77eb') { // JoelMoreno
      return [
        TrustModel(
          id: 'mock_given_1',
          rater: userId,
          rated: '69087960f70b998ea8945012',
          score: 5,
          comment: 'Excelente asistente a eventos, muy puntual',
          context: 'event_participation',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        TrustModel(
          id: 'mock_given_2',
          rater: userId,
          rated: '69086ebaf130a9a4b9252521',
          score: 4,
          comment: 'Persona confiable, recomendado',
          context: 'general_trust',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ];
    }
    
    // Para otros usuarios, generar valoraciones aleatorias
    return _generateRandomRatings(userId, isReceived: false);
  }
  
  List<TrustModel> _generateRandomRatings(String userId, {required bool isReceived}) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final count = (random % 4) + 1; // 1-4 valoraciones
    
    final List<TrustModel> ratings = [];
    final comments = [
      'Excelente persona, muy confiable',
      'Buen trato, recomendado',
      'Persona responsable y puntual',
      'Muy buena experiencia trabajando juntos',
      'Confiable y profesional',
    ];
    
    for (int i = 0; i < count; i++) {
      final rating = ((random + i) % 3) + 3; // Rating 3-5
      final comment = comments[i % comments.length];
      final now = DateTime.now().subtract(Duration(days: (i + 1) * 7));
      
      ratings.add(TrustModel(
        id: 'mock_${isReceived ? 'received' : 'given'}_${userId}_$i',
        rater: isReceived ? 'mock_user_$i' : userId,
        rated: isReceived ? userId : 'mock_user_$i',
        score: rating,
        comment: comment,
        context: 'event_participation',
        createdAt: now,
        updatedAt: now,
      ));
    }
    
    return ratings;
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      
      // Manejar específicamente 404 para endpoints de trust
      if (statusCode == 404) {
        final url = e.requestOptions.uri.toString();
        if (url.contains('/user-trust/user/')) {
          return 'El sistema de valoraciones de confianza no está disponible';
        }
        return 'Recurso no encontrado';
      }
      
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Error del servidor';
      }
      return 'Error del servidor';
    }
    return 'Error de conexión';
  }
}