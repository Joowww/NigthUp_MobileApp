import 'package:NightUp_MobileApp/Models/user.dart';
import 'package:NightUp_MobileApp/Services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/auth_controller.dart';

class UserController extends GetxController {
  var isLoading = true.obs;
  var userList = <User>[].obs;
  var selectedUser = Rxn<User>();
  final UserServices _userServices;

  UserController(this._userServices);

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }

  void fetchUsers() async {
    try {
      isLoading(true);
      var users = await _userServices.fetchUsers();
      if (users.isNotEmpty) {
        userList.assignAll(users);
      }
    } finally {
      isLoading(false);
    }
  }

  fetchUserById(String id) async {
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

  void updateUser(String id, User updatedUser) async {
    try {
      isLoading(true);
      var user = await _userServices.updateUser(id, updatedUser);
      
      final AuthController authController = Get.find<AuthController>();
      if (authController.currentUser.value?.id == id) {
        authController.currentUser.value = user;
      }
      
      final index = userList.indexWhere((u) => u.id == id);
      if (index != -1) {
        userList[index] = user;
      }
      
      Get.snackbar(
        "¡Éxito!",
        "Usuario actualizado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error al actualizar",
        "No se pudo actualizar el usuario: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }
}