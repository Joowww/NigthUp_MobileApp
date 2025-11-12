import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/business.dart';
import '../Services/business_services.dart';
import '../Controllers/auth_controller.dart';

class BusinessController extends GetxController {
  var isLoading = true.obs;
  var businessList = <Business>[].obs;
  var selectedBusiness = Rxn<Business>();
  final BusinessServices _businessServices;

  BusinessController(this._businessServices);

  @override
  void onInit() {
    fetchBusinesses();
    super.onInit();
  }

  void fetchBusinesses() async {
    try {
      isLoading(true);
      var businesses = await _businessServices.fetchBusinesses();
      businessList.assignAll(businesses);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar los negocios: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchBusinessById(String id) async {
    try {
      isLoading(true);
      var business = await _businessServices.fetchBusinessById(id);
      selectedBusiness.value = business;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar el negocio: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> createBusiness(Map<String, dynamic> businessData) async {
    try {
      isLoading(true);
      final newBusiness = await _businessServices.createBusiness(businessData);
      businessList.insert(0, newBusiness);
      Get.back();
      Get.snackbar(
        "Éxito",
        "Negocio creado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo crear el negocio: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateBusiness(String businessId, Map<String, dynamic> businessData) async {
    try {
      isLoading(true);
      final updatedBusiness = await _businessServices.updateBusiness(businessId, businessData);
      
      // Actualizar en la lista
      final index = businessList.indexWhere((business) => business.id == businessId);
      if (index != -1) {
        businessList[index] = updatedBusiness;
      }
      
      // Actualizar negocio seleccionado si es el mismo
      if (selectedBusiness.value?.id == businessId) {
        selectedBusiness.value = updatedBusiness;
      }
      
      Get.back();
      Get.snackbar(
        "Éxito",
        "Negocio actualizado correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar el negocio: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void refreshBusinesses() {
    fetchBusinesses();
  }

  List<Business> get managedBusinesses {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUser.value?.id;
    if (currentUserId == null) return [];
    
    return businessList.where((business) => business.managers.contains(currentUserId)).toList();
  }
}