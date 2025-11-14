import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../app/themes/app_colors.dart';
import 'package:flutter/material.dart';

class UsersController extends GetxController {
  final UserRepository _userRepository = UserRepository();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<UserModel> filteredUsers = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasMore = true.obs;
  final RxInt totalUsers = 0.obs;

  int _currentSkip = 0;
  final int _limit = 20;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers({bool loadMore = false}) async {
    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        _currentSkip = 0;
        users.clear();
      }

      final result = await _userRepository.getUsers(
        skip: loadMore ? _currentSkip : 0,
        limit: _limit,
      );
      
      final newUsers = result['users'] as List<UserModel>;
      hasMore.value = result['hasMore'] as bool;
      totalUsers.value = result['total'] as int;
      
      if (loadMore) {
        users.addAll(newUsers);
      } else {
        users.value = newUsers;
      }
      
      _currentSkip += newUsers.length;
      filterUsers();
      
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
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreUsers() async {
    if (!hasMore.value || isLoadingMore.value) return;
    await loadUsers(loadMore: true);
  }

  void searchUsers(String query) {
    searchQuery.value = query.toLowerCase();
    filterUsers();
  }

  void filterUsers() {
    if (searchQuery.value.isEmpty) {
      filteredUsers.value = users;
    } else {
      filteredUsers.value = users.where((user) {
        return user.username.toLowerCase().contains(searchQuery.value) ||
            user.email.toLowerCase().contains(searchQuery.value);
      }).toList();
    }
  }

  Future<void> refreshUsers() async {
    await loadUsers();
  }
}