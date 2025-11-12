import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/user_trust.dart';
import '../Services/user_trust_services.dart';
import '../Controllers/auth_controller.dart';

class UserTrustController extends GetxController {
  var isLoading = true.obs;
  var trustList = <UserTrust>[].obs;
  var selectedTrust = Rxn<UserTrust>();
  var userTrustStats = <String, dynamic>{}.obs;
  var userTrustSummary = <String, dynamic>{}.obs;
  final UserTrustServices _userTrustServices;

  UserTrustController(this._userTrustServices);

  @override
  void onInit() {
    fetchTrustRatings();
    super.onInit();
  }

  void fetchTrustRatings() async {
    try {
      isLoading(true);
      var trustRatings = await _userTrustServices.fetchTrustRatings();
      trustList.assignAll(trustRatings);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las valoraciones de confianza: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTrustRatingById(String id) async {
    try {
      isLoading(true);
      var trustRating = await _userTrustServices.fetchTrustRatingById(id);
      selectedTrust.value = trustRating;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar la valoración de confianza: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTrustRatingsByUser(String userId) async {
    try {
      isLoading(true);
      var trustRatings = await _userTrustServices.fetchTrustRatingsByUser(userId);
      trustList.assignAll(trustRatings);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las valoraciones de confianza del usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTrustRatingsFromUser(String userId) async {
    try {
      isLoading(true);
      var trustRatings = await _userTrustServices.fetchTrustRatingsFromUser(userId);
      trustList.assignAll(trustRatings);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las valoraciones de confianza del usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> createTrustRating(Map<String, dynamic> trustData) async {
    try {
      isLoading(true);
      final newTrustRating = await _userTrustServices.createTrustRating(trustData);
      trustList.insert(0, newTrustRating);
      Get.back();
      Get.snackbar(
        "Éxito",
        "Valoración de confianza creada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo crear la valoración de confianza: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateTrustRating(String trustId, Map<String, dynamic> trustData) async {
    try {
      isLoading(true);
      final updatedTrustRating = await _userTrustServices.updateTrustRating(trustId, trustData);
      
      // Actualizar en la lista
      final index = trustList.indexWhere((trust) => trust.id == trustId);
      if (index != -1) {
        trustList[index] = updatedTrustRating;
      }
      
      // Actualizar trust seleccionado si es el mismo
      if (selectedTrust.value?.id == trustId) {
        selectedTrust.value = updatedTrustRating;
      }
      
      Get.back();
      Get.snackbar(
        "Éxito",
        "Valoración de confianza actualizada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar la valoración de confianza: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteTrustRating(String trustId) async {
    try {
      isLoading(true);
      final success = await _userTrustServices.deleteTrustRating(trustId);
      if (success) {
        trustList.removeWhere((trust) => trust.id == trustId);
        if (selectedTrust.value?.id == trustId) {
          selectedTrust.value = null;
        }
        Get.snackbar(
          "Éxito",
          "Valoración de confianza eliminada correctamente",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo eliminar la valoración de confianza: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUserTrustStats(String userId) async {
    try {
      final result = await _userTrustServices.getUserTrustStats(userId);
      if (result['success'] == true) {
        userTrustStats.value = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching user trust stats: $e');
    }
  }

  Future<void> fetchUserTrustSummary(String userId) async {
    try {
      final result = await _userTrustServices.getUserTrustSummary(userId);
      if (result['success'] == true) {
        userTrustSummary.value = result['summary'] ?? {};
      }
    } catch (e) {
      print('Error fetching user trust summary: $e');
    }
  }

  void refreshTrustRatings() {
    fetchTrustRatings();
  }

  List<UserTrust> get myGivenTrustRatings {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUser.value?.id;
    if (currentUserId == null) return [];
    
    return trustList.where((trust) => trust.rater == currentUserId).toList();
  }

  List<UserTrust> get myReceivedTrustRatings {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUser.value?.id;
    if (currentUserId == null) return [];
    
    return trustList.where((trust) => trust.rated == currentUserId).toList();
  }
}