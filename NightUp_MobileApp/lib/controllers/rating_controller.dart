import 'package:get/get.dart';
import '../services/api_service.dart';

class RatingController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  Future<bool> submitRating({
    required String eventId,
    required int score,
    required String comment,
  }) async {
    try {
      final userId = _apiService.getUserId();
      if (userId == null) {
        return false;
      }

      await _apiService.post(
        '/rating',
        data: {
          'eventId': eventId,
          'username': userId,
          'score': score,
          'comment': comment,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRating({
    required String ratingId,
    required int score,
    required String comment,
  }) async {
    try {
      await _apiService.patch(
        '/rating/$ratingId',
        data: {'score': score, 'comment': comment},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRating(String ratingId) async {
    try {
      await _apiService.delete('/rating/$ratingId');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getEventRatingStats(String eventId) async {
    try {
      final response = await _apiService.get('/rating/event/$eventId/stats');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEventRatings(String eventId) async {
    try {
      final response = await _apiService.get('/rating/event/$eventId');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['ratings'] is List) {
        return List<Map<String, dynamic>>.from(response.data['ratings']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserEventRating(String eventId) async {
    try {
      final userId = _apiService.getUserId();
      if (userId == null) return null;

      final response = await _apiService.get(
        '/rating/user/$userId/event/$eventId',
      );
      if (response.data is Map && response.data.isNotEmpty) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
