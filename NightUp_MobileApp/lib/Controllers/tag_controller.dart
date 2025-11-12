import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Models/tag.dart';
import '../Services/tag_services.dart';

class TagController extends GetxController {
  var isLoading = true.obs;
  var tagList = <Tag>[].obs;
  var selectedTag = Rxn<Tag>();
  var tagStats = <String, dynamic>{}.obs;
  final TagServices _tagServices;

  TagController(this._tagServices);

  @override
  void onInit() {
    fetchTags();
    fetchTagStats();
    super.onInit();
  }

  void fetchTags() async {
    try {
      isLoading(true);
      var tags = await _tagServices.fetchTags();
      tagList.assignAll(tags);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron cargar las etiquetas: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTagById(String id) async {
    try {
      isLoading(true);
      var tag = await _tagServices.fetchTagById(id);
      selectedTag.value = tag;
    } catch (e) {
      Get.snackbar(
        "Error al cargar",
        "No se pudo encontrar la etiqueta: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTagStats() async {
    try {
      final result = await _tagServices.getTagStats();
      if (result['success'] == true) {
        tagStats.value = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching tag stats: $e');
    }
  }

  Future<void> createTag(Map<String, dynamic> tagData) async {
    try {
      isLoading(true);
      final newTag = await _tagServices.createTag(tagData);
      tagList.insert(0, newTag);
      Get.back();
      Get.snackbar(
        "Éxito",
        "Etiqueta creada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo crear la etiqueta: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateTag(String tagId, Map<String, dynamic> tagData) async {
    try {
      isLoading(true);
      final updatedTag = await _tagServices.updateTag(tagId, tagData);
      
      // Actualizar en la lista
      final index = tagList.indexWhere((tag) => tag.id == tagId);
      if (index != -1) {
        tagList[index] = updatedTag;
      }
      
      // Actualizar tag seleccionado si es el mismo
      if (selectedTag.value?.id == tagId) {
        selectedTag.value = updatedTag;
      }
      
      Get.back();
      Get.snackbar(
        "Éxito",
        "Etiqueta actualizada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo actualizar la etiqueta: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void refreshTags() {
    fetchTags();
    fetchTagStats();
  }
}