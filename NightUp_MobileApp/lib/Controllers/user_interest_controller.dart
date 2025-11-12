import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/user_interest.dart';
import '../Services/user_interest_services.dart';
import '../Controllers/auth_controller.dart';

class UserInterestController extends GetxController {
  var isLoading = true.obs;
  var interestList = <UserInterest>[].obs;
  var selectedInterest = Rxn<UserInterest>();
  var interestStats = <String, dynamic>{}.obs;
  final UserInterestServices _userInterestServices;

  UserInterestController(this._userInterestServices);

  @override
  void onInit() {
    fetchUserInterests();
    fetchInterestStats();
    super.onInit();
  }

  void fetchUserInterests() async {
    try {
      isLoading(true);
      var interests = await _userInterestServices.fetchUserInterests();
      interestList.assignAll(interests);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar los intereses: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUserInterestById(String id) async {
    try {
      isLoading(true);
      var interest = await _userInterestServices.fetchUserInterestById(id);
      selectedInterest.value = interest;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar el interés: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUserInterestsByUser(String userId) async {
    try {
      isLoading(true);
      var interests = await _userInterestServices.fetchUserInterestsByUser(userId);
      interestList.assignAll(interests);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar los intereses del usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchInterestStats() async {
    try {
      final result = await _userInterestServices.getUserInterestStats();
      if (result['success'] == true) {
        interestStats.value = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching interest stats: $e');
    }
  }

  Future<void> createUserInterest(Map<String, dynamic> interestData) async {
    try {
      isLoading(true);
      final newInterest = await _userInterestServices.createUserInterest(interestData);
      interestList.insert(0, newInterest);
      Get.back();
      Get.snackbar(
        "Éxito",
        "Interés creado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo crear el interés: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateUserInterest(String interestId, Map<String, dynamic> interestData) async {
    try {
      isLoading(true);
      final updatedInterest = await _userInterestServices.updateUserInterest(interestId, interestData);
      
      // Actualizar en la lista
      final index = interestList.indexWhere((interest) => interest.id == interestId);
      if (index != -1) {
        interestList[index] = updatedInterest;
      }
      
      // Actualizar interés seleccionado si es el mismo
      if (selectedInterest.value?.id == interestId) {
        selectedInterest.value = updatedInterest;
      }
      
      Get.back();
      Get.snackbar(
        "Éxito",
        "Interés actualizado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar el interés: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void refreshUserInterests() {
    fetchUserInterests();
    fetchInterestStats();
  }

  List<UserInterest> get myInterests {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUser.value?.id;
    if (currentUserId == null) return [];
    
    return interestList.where((interest) => interest.users.contains(currentUserId)).toList();
  }
}