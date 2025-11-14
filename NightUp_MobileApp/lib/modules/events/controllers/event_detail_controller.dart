import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/rating_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/rating_repository.dart';

class EventDetailController extends GetxController {
  final EventRepository _eventRepository = EventRepository();
  final RatingRepository _ratingRepository = RatingRepository();

  final Rx<EventModel?> event = Rx<EventModel?>(null);
  final RxList<RatingModel> ratings = <RatingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isJoined = false.obs;
  final RxDouble averageRating = 0.0.obs;

  Future<void> loadEventDetail(String eventId) async {
    try {
      isLoading.value = true;
      event.value = await _eventRepository.getEventById(eventId);
      await loadEventRatings(eventId);
      // TODO: Verificar si el usuario ya está unido al evento
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadEventRatings(String eventId) async {
    try {
      final fetchedRatings = await _ratingRepository.getEventRatings(eventId);
      ratings.value = fetchedRatings;
      if (ratings.isNotEmpty) {
        // Safer calculation with explicit type handling
        double total = 0.0;
        for (var rating in ratings) {
          try {
            total += rating.score.toDouble();
          } catch (e) {
            print('Warning: Invalid score for rating ${rating.id}: ${rating.score}');
          }
        }
        averageRating.value = total / ratings.length;
      } else {
        averageRating.value = 0.0;
      }
      print('Loaded ${ratings.length} ratings for event $eventId, average: ${averageRating.value}');
    } catch (e) {
      print('Error loading ratings: $e');
      print('Error details: ${e.runtimeType}');
      ratings.clear();
      averageRating.value = 0.0;
    }
  }

  Future<void> joinEvent() async {
    if (event.value == null) return;
    
    try {
      await _eventRepository.joinEvent(event.value!.id);
      isJoined.value = true;
      
      // Actualizar el evento
      await loadEventDetail(event.value!.id);
      
      Get.snackbar(
        '¡Éxito!',
        'Te has unido al evento',
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> leaveEvent() async {
    if (event.value == null) return;
    
    try {
      await _eventRepository.leaveEvent(event.value!.id);
      isJoined.value = false;
      
      // Actualizar el evento
      await loadEventDetail(event.value!.id);
      
      Get.snackbar(
        'Éxito',
        'Has salido del evento',
        backgroundColor: AppColors.info.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> addRating(int score, String? comment) async {
    if (event.value == null) return;
    
    try {
      await _ratingRepository.createRating(
        eventId: event.value!.id,
        score: score,
        comment: comment,
      );
      
      await loadEventRatings(event.value!.id);
      
      Get.back();
      Get.snackbar(
        '¡Gracias!',
        'Tu valoración ha sido enviada',
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}