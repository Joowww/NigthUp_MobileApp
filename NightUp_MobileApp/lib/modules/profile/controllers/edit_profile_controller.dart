import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/user_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class EditProfileController extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final UserService _userService = Get.find();

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();

  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    super.onClose();
  }

  Future<void> loadCurrentUser() async {
    try {
      isLoading.value = true;
      final user = await _userService.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        usernameController.text = user.username;
        emailController.text = user.email;
        
        // Manejo seguro de la fecha de cumpleaños
        if (user.birthday != null && user.birthday!.isNotEmpty) {
          try {
            final birthdayDate = DateTime.parse(user.birthday!);
            birthdayController.text = _formatDate(birthdayDate);
          } catch (e) {
            print('Error parsing birthday: $e');
            birthdayController.text = '';
          }
        } else {
          birthdayController.text = '';
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cargar la información del perfil',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Parse birthday if provided
      DateTime? birthday;
      if (birthdayController.text.trim().isNotEmpty) {
        try {
          birthday = _parseDate(birthdayController.text.trim());
        } catch (e) {
          Get.snackbar(
            'Error',
            'Formato de fecha inválido. Use DD/MM/YYYY',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
          return;
        }
      }

      final updatedUser = await _userRepository.updateProfile(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        birthday: birthday?.toIso8601String(),
      );

      // Update current user in service
      try {
        _userService.setCurrentUser(updatedUser);
      } catch (e) {
        print('UserService not available: $e');
      }
      currentUser.value = updatedUser;

      Get.snackbar(
        'Éxito',
        'Perfil actualizado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Go back to previous screen
      Get.back();

    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar el perfil: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectDate() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (currentUser.value?.birthday != null) {
      try {
        initialDate = DateTime.parse(currentUser.value!.birthday!);
      } catch (e) {
        // Si no se puede parsear, usar fecha por defecto
      }
    }
    
    DateTime? pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      birthdayController.text = _formatDate(pickedDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) {
      throw 'Fecha vacía';
    }
    
    final parts = dateStr.trim().split('/');
    if (parts.length != 3) {
      throw 'Formato de fecha inválido. Use DD/MM/YYYY';
    }
    
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > DateTime.now().year) {
        throw 'Fecha inválida';
      }
      
      return DateTime(year, month, day);
    } catch (e) {
      if (e is FormatException) {
        throw 'Formato de fecha inválido. Use DD/MM/YYYY';
      }
      throw e.toString();
    }
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de usuario es requerido';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 20) {
      return 'El nombre no puede tener más de 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Solo se permiten letras, números y guiones bajos';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Ingrese un email válido';
    }
    return null;
  }

  String? validateBirthday(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Birthday is optional
    }
    
    try {
      final date = _parseDate(value.trim());
      final now = DateTime.now();
      
      if (date.isAfter(now)) {
        return 'La fecha no puede ser futura';
      }
      
      final age = now.year - date.year;
      if (age < 13) {
        return 'Debe ser mayor de 13 años';
      }
      
      return null;
    } catch (e) {
      return 'Formato inválido. Use DD/MM/YYYY';
    }
  }
}