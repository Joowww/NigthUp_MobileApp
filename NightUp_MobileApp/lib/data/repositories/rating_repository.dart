import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/user_service.dart';
import '../models/rating_model.dart';

class RatingRepository {
  final ApiService _apiService = ApiService();

  Future<List<RatingModel>> getRatings() async {
    try {
      final response = await _apiService.get(ApiConstants.ratings);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => RatingModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<RatingModel>> getEventRatings(String eventId) async {
    try {
      print('Getting ratings for event: $eventId');
      final response = await _apiService.get(
        ApiConstants.eventRatings.replaceAll('{id}', eventId),
      );
      print('Raw rating response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');
      
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['data'] ?? response.data['ratings'] ?? []);
      
      print('Extracted data: $data');
      print('Data length: ${data.length}');
      
      final ratings = <RatingModel>[];
      for (var i = 0; i < data.length; i++) {
        try {
          final json = data[i];
          print('Converting rating JSON: $json');
          final rating = RatingModel.fromJson(json);
          ratings.add(rating);
        } catch (e) {
          print('Error converting rating at index $i: $e');
          print('Problematic JSON: ${data[i]}');
          // Skip this rating and continue with others
        }
      }
      
      print('Successfully converted ${ratings.length} ratings');
      return ratings;
    } on DioException catch (e) {
      print('Error getting event ratings: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error in getEventRatings: $e');
      rethrow;
    }
  }

  Future<RatingModel> createRating({
    required String eventId,
    required int score,
    String? comment,
  }) async {
    try {
      // Get current user info
      final userService = Get.find<UserService>();
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser == null) {
        throw 'Usuario no autenticado';
      }

      final response = await _apiService.post(
        ApiConstants.ratings,
        data: {
          'event': eventId,
          'score': score,
          'username': currentUser.username,
          if (comment != null) 'comment': comment,
        },
      );
      return RatingModel.fromJson(response.data['data'] ?? response.data);
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