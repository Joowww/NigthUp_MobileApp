import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/user.dart';
import '../Services/user_services.dart';
import '../Controllers/auth_controller.dart';

class UserController extends GetxController {
  var isLoading = true.obs;
  var userList = <User>[].obs;
  var selectedUser = Rxn<User>();
  var userStats = <String, dynamic>{}.obs;
  final UserServices _userServices;

  UserController(this._userServices);

  @override
  void onInit() {
    fetchUsers();
    fetchUserStats();
    super.onInit();
  }

  void fetchUsers() async {
    try {
      isLoading(true);
      var users = await _userServices.fetchUsers();
      userList.assignAll(users);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar los usuarios: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUserById(String id) async {
    try {
      isLoading(true);
      var user = await _userServices.fetchUserById(id);
      selectedUser.value = user;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar el usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUserStats() async {
    try {
      final result = await _userServices.getUserStats();
      if (result['success'] == true) {
        userStats.value = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching user stats: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      isLoading(true);
      final authController = Get.find<AuthController>();
      final currentUserId = authController.currentUser.value?.id;
      
      if (currentUserId != null) {
        final updatedUser = await _userServices.updateUserProfile(currentUserId, userData);
        authController.currentUser.value = updatedUser;
        Get.snackbar(
          "Éxito",
          "Perfil actualizado correctamente",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar el perfil: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void refreshUsers() {
    fetchUsers();
    fetchUserStats();
  }
}