import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final StorageService _storage = StorageService();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    isLoggedIn.value = await _authRepository.isLoggedIn();
    if (isLoggedIn.value) {
      await loadCurrentUser();
    }
  }

  Future<void> loadCurrentUser() async {
    final userData = await _storage.getUser();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.login(
        username: username,
        password: password,
      );
      
      currentUser.value = response.user;
      isLoggedIn.value = true;
      
      Get.snackbar(
        'Éxito',
        response.message ?? 'Inicio de sesión exitoso',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? birthday,
  }) async {
    try {
      isLoading.value = true;
      await _authRepository.register(
        username: username,
        email: email,
        password: password,
        birthday: birthday,
      );
      
      // Para registro, NO establecer usuario como loggeado
      // El usuario deberá hacer login después del registro
      Get.snackbar(
        'Éxito',
        'Registro exitoso. Ahora puedes iniciar sesión',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authRepository.logout();
      currentUser.value = null;
      isLoggedIn.value = false;
      
      Get.snackbar(
        'Éxito',
        'Sesión cerrada correctamente',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }
}