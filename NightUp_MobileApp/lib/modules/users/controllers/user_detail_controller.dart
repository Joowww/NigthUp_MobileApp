import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/trust_repository.dart';

class UserDetailController extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final TrustRepository _trustRepository = TrustRepository();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxList<EventModel> userEvents = <EventModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt trustLevel = 0.obs;

  Future<void> loadUserDetail(String userId) async {
    try {
      isLoading.value = true;
      user.value = await _userRepository.getUserById(userId);
      // TODO: Cargar eventos del usuario si el backend lo soporta
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

  Future<void> rateTrust(int level, String? context) async {
    if (user.value == null) return;
    
    try {
      await _trustRepository.rateTrust(
        ratedId: user.value!.id,
        score: level,
        comment: null,
        context: context ?? 'user_profile',
      );
      
      trustLevel.value = level;
      
      Get.back();
      Get.snackbar(
        'Éxito',
        'Valoración de confianza enviada',
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