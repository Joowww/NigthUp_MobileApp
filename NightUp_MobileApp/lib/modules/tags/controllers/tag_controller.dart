import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../data/models/tag_model.dart';
import '../../../data/repositories/tag_repository.dart';

class TagsController extends GetxController {
  final TagRepository _tagRepository = TagRepository();

  final RxList<TagModel> tags = <TagModel>[].obs;
  final RxList<TagModel> filteredTags = <TagModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTags();
  }

  Future<void> loadTags() async {
    try {
      isLoading.value = true;
      final result = await _tagRepository.getTags();
      tags.value = result;
      filterTags();
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

  void searchTags(String query) {
    searchQuery.value = query.toLowerCase();
    filterTags();
  }

  void filterTags() {
    if (searchQuery.value.isEmpty) {
      filteredTags.value = tags;
    } else {
      filteredTags.value = tags.where((tag) {
        return tag.name.toLowerCase().contains(searchQuery.value);
      }).toList();
    }
  }

  Future<void> refreshTags() async {
    await loadTags();
  }

  Future<void> createNewTag(String name, String color, String? description) async {
    try {
      isLoading.value = true;
      
      // Crear el nuevo tag
      final newTag = await _tagRepository.createTag(
        name: name,
        color: color,
        description: description,
      );
      
      // Añadir a la lista de tags
      tags.add(newTag);
      filterTags();
      
      Get.snackbar(
        'Creado',
        'Nuevo tag "$name" creado exitosamente',
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
        'No se pudo crear el tag: ${e.toString()}',
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