import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/rating.dart';
import '../Services/rating_services.dart';
import '../Controllers/auth_controller.dart';

class RatingController extends GetxController {
  var isLoading = true.obs;
  var ratingList = <Rating>[].obs;
  var selectedRating = Rxn<Rating>();
  var eventRatingStats = <String, dynamic>{}.obs;
  final RatingServices _ratingServices;

  RatingController(this._ratingServices);

  @override
  void onInit() {
    fetchRatings();
    super.onInit();
  }

  void fetchRatings() async {
    try {
      isLoading(true);
      var ratings = await _ratingServices.fetchRatings();
      ratingList.assignAll(ratings);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las valoraciones: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRatingById(String id) async {
    try {
      isLoading(true);
      var rating = await _ratingServices.fetchRatingById(id);
      selectedRating.value = rating;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar la valoración: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRatingsByEvent(String eventId) async {
    try {
      isLoading(true);
      var ratings = await _ratingServices.fetchRatingsByEvent(eventId);
      ratingList.assignAll(ratings);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las valoraciones del evento: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRatingsByUser(String username) async {
    try {
      isLoading(true);
      var ratings = await _ratingServices.fetchRatingsByUser(username);
      ratingList.assignAll(ratings);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las valoraciones del usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> createRating(Map<String, dynamic> ratingData) async {
    try {
      isLoading(true);
      final newRating = await _ratingServices.createRating(ratingData);
      ratingList.insert(0, newRating);
      Get.back();
      Get.snackbar(
        "Éxito",
        "Valoración creada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo crear la valoración: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateRating(String ratingId, Map<String, dynamic> ratingData) async {
    try {
      isLoading(true);
      final updatedRating = await _ratingServices.updateRating(ratingId, ratingData);
      
      // Actualizar en la lista
      final index = ratingList.indexWhere((rating) => rating.id == ratingId);
      if (index != -1) {
        ratingList[index] = updatedRating;
      }
      
      // Actualizar rating seleccionado si es el mismo
      if (selectedRating.value?.id == ratingId) {
        selectedRating.value = updatedRating;
      }
      
      Get.back();
      Get.snackbar(
        "Éxito",
        "Valoración actualizada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar la valoración: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteRating(String ratingId) async {
    try {
      isLoading(true);
      final success = await _ratingServices.deleteRating(ratingId);
      if (success) {
        ratingList.removeWhere((rating) => rating.id == ratingId);
        if (selectedRating.value?.id == ratingId) {
          selectedRating.value = null;
        }
        Get.snackbar(
          "Éxito",
          "Valoración eliminada correctamente",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo eliminar la valoración: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchEventRatingStats(String eventId) async {
    try {
      final result = await _ratingServices.getEventRatingStats(eventId);
      if (result['success'] == true) {
        eventRatingStats.value = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching event rating stats: $e');
    }
  }

  Future<Rating?> getUserEventRating(String eventId) async {
    try {
      final authController = Get.find<AuthController>();
      final currentUsername = authController.currentUser.value?.username;
      if (currentUsername == null) return null;
      
      return await _ratingServices.getUserEventRating(currentUsername, eventId);
    } catch (e) {
      print('Error getting user event rating: $e');
      return null;
    }
  }

  void refreshRatings() {
    fetchRatings();
  }

  List<Rating> get myRatings {
    final authController = Get.find<AuthController>();
    final currentUsername = authController.currentUser.value?.username;
    if (currentUsername == null) return [];
    
    return ratingList.where((rating) => rating.username == currentUsername).toList();
  }
}