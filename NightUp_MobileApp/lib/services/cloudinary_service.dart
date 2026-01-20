import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'image_picker_service.dart';

class AppColors {
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFFEC4899);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class CloudinaryService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final ImagePicker _picker = ImagePicker();

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
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await ImagePickerService.pickImage(
        source: ImageSource.camera,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadImage(XFile file, {String folder = 'chat'}) async {
    try {
      final imageUrl = await _apiService.uploadToCloudinary(file, folder);
      if (imageUrl != null) {
        return imageUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadAudio(
    String path, {
    String folder = 'chat_audio',
  }) async {
    try {
      final xFile = XFile(path);
      final audioUrl = await _apiService.uploadToCloudinary(
        xFile,
        folder,
        resourceType: 'video',
      );

      if (audioUrl != null) {
        return audioUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> showImagePickerDialog() async {
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

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );
    final url = await uploadImage(pickedFile);
    Get.back();
    return url;
  }
}
