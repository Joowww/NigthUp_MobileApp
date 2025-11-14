import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/user_repository.dart';

class ChangePasswordController extends GetxController {
  final UserRepository _userRepository = UserRepository();

  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool showCurrentPassword = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      await _userRepository.changePassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      Get.snackbar(
        'Éxito',
        'Contraseña cambiada correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Clear fields and go back
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      
      Get.back();

    } catch (e) {
      String errorMessage = 'No se pudo cambiar la contraseña';
      
      if (e.toString().contains('Invalid current password') ||
          e.toString().contains('current password')) {
        errorMessage = 'La contraseña actual es incorrecta';
      } else if (e.toString().contains('weak') || 
                 e.toString().contains('password')) {
        errorMessage = 'La nueva contraseña es muy débil';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleCurrentPasswordVisibility() {
    showCurrentPassword.value = !showCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    showNewPassword.value = !showNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  String? validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña actual es requerida';
    }
    if (value.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La nueva contraseña es requerida';
    }
    if (value.trim().length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value.trim())) {
      return 'Debe contener al menos: 1 mayúscula, 1 minúscula y 1 número';
    }
    if (value.trim() == currentPasswordController.text.trim()) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirme la nueva contraseña';
    }
    if (value.trim() != newPasswordController.text.trim()) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}