import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/business_model.dart';
import '../../../data/repositories/business_repository.dart';

class BusinessController extends GetxController {
  final BusinessRepository _businessRepository = BusinessRepository();

  final RxList<BusinessModel> businesses = <BusinessModel>[].obs;
  final RxList<BusinessModel> filteredBusinesses = <BusinessModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBusinesses();
  }

  Future<void> loadBusinesses() async {
    try {
      isLoading.value = true;
      final result = await _businessRepository.getBusinesses();
      businesses.value = result;
      filterBusinesses();
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

  void searchBusinesses(String query) {
    searchQuery.value = query.toLowerCase();
    filterBusinesses();
  }

  void filterBusinesses() {
    if (searchQuery.value.isEmpty) {
      filteredBusinesses.value = businesses;
    } else {
      filteredBusinesses.value = businesses.where((business) {
        return business.name.toLowerCase().contains(searchQuery.value) ||
            (business.address?.toLowerCase().contains(searchQuery.value) ?? false);
      }).toList();
    }
  }

  Future<void> refreshBusinesses() async {
    await loadBusinesses();
  }
}