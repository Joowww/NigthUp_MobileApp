import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'image_picker_service.dart';
// import 'dart:io'; // Removed for web compatibility
import 'dart:developer';

class AppColors {
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFFEC4899);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class CloudinaryService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final ImagePicker _picker = ImagePicker();

  // ==================== SELECCIONAR IMAGEN ====================

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      log('❌ Error picking image: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      // Use ImagePickerService to handle Web Camera properly
      final XFile? image = await ImagePickerService.pickImage(
        source: ImageSource.camera,
      );
      return image;
    } catch (e) {
      log('❌ Error taking photo: $e');
      return null;
    }
  }

  // ==================== SUBIR A CLOUDINARY ====================

  Future<String?> uploadImage(XFile file, {String folder = 'chat'}) async {
    try {
      log('📤 Uploading image to Cloudinary...');

      final imageUrl = await _apiService.uploadToCloudinary(file, folder);

      if (imageUrl != null) {
        log('✅ Image uploaded: $imageUrl');
        return imageUrl;
      } else {
        log('❌ Upload failed: No URL returned');
        return null;
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
      return null;
    }
  }

  // ==================== SUBIR AUDIO ====================

  Future<String?> uploadAudio(
    String path, {
    String folder = 'chat_audio',
  }) async {
    try {
      log('📤 Uploading audio to Cloudinary from path: $path');

      final xFile = XFile(path);

      // Usamos el mismo método de ApiService, que internamente usa MultipartFile.
      // ApiService debería encargarse de manejar XFile correctamente (readAsBytes o path).
      final audioUrl = await _apiService.uploadToCloudinary(
        xFile,
        folder,
        resourceType: 'video',
      );

      if (audioUrl != null) {
        log('✅ Audio uploaded: $audioUrl');
        return audioUrl;
      } else {
        log('❌ Audio Upload failed');
        return null;
      }
    } catch (e) {
      log('❌ Error uploading audio: $e');
      return null;
    }
  }

  // ==================== MOSTRAR DIÁLOGO DE SELECCIÓN ====================

  Future<String?> showImagePickerDialog() async {
    // 1. Obtener la imagen seleccionada desde el diálogo
    final XFile? pickedFile = await Get.dialog<XFile?>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[900]!, Colors.black],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Galería
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Galería',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final image = await pickImageFromGallery();
                  Get.back(result: image);
                },
              ),

              const SizedBox(height: 12),

              // Cámara
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text(
                  'Cámara',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final image = await pickImageFromCamera();
                  Get.back(result: image);
                },
              ),

              const SizedBox(height: 24),

              // Cancelar
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (pickedFile == null) return null;

    // 2. Mostrar Loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );

    // 3. Subir Imagen
    final url = await uploadImage(pickedFile);

    // 4. Cerrar Loading
    Get.back();

    // 5. Retornar URL
    return url;
  }
}
