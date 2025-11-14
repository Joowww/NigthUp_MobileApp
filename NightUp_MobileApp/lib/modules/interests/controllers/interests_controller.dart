import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/interest_model.dart';
import '../../../data/repositories/interest_repository.dart';

class InterestsController extends GetxController {
  final InterestRepository _interestRepository = InterestRepository();

  final RxList<InterestModel> allInterests = <InterestModel>[].obs;
  final RxList<InterestModel> userInterests = <InterestModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadAllInterests(),
      loadUserInterests(),
    ]);
  }

  Future<void> loadAllInterests() async {
    try {
      isLoading.value = true;
      allInterests.value = await _interestRepository.getInterests();
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

  Future<void> loadUserInterests() async {
    try {
      userInterests.value = await _interestRepository.getUserInterests();
    } catch (e) {
      print('Error loading user interests: $e');
    }
  }

  bool isInterestAdded(String interestId) {
    return userInterests.any((interest) => interest.id == interestId);
  }

  Future<void> toggleInterest(InterestModel interest) async {
    try {
      if (isInterestAdded(interest.id)) {
        await _interestRepository.removeUserInterest(interest.id);
        userInterests.removeWhere((i) => i.id == interest.id);
        
        Get.snackbar(
          'Eliminado',
          'Interés eliminado de tu perfil',
          backgroundColor: AppColors.info.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      } else {
        await _interestRepository.addUserInterest(interest.id);
        userInterests.add(interest);
        
        Get.snackbar(
          'Añadido',
          'Interés añadido a tu perfil',
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
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

  Future<void> refreshData() async {
    await loadData();
  }

  Future<void> createNewInterest(String name, String? description) async {
    try {
      isLoading.value = true;
      
      // Crear el nuevo interés
      final newInterest = await _interestRepository.createInterest(
        name: name,
        description: description,
      );
      
      // Añadir a la lista de todos los intereses
      allInterests.add(newInterest);
      
      // Opcional: añadirlo automáticamente a los intereses del usuario
      await _interestRepository.addUserInterest(newInterest.id);
      userInterests.add(newInterest);
      
      Get.snackbar(
        'Creado',
        'Nuevo interés "$name" creado y añadido a tu perfil',
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear el interés: ${e.toString()}',
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
}