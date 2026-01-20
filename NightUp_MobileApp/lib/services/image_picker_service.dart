import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/web_camera_dialog.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<ImageSource?> showImageSourceDialog() async {
    return await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Image Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Take a new photo',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Choose from library',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  static Future<XFile?> pickImage({ImageSource? source}) async {
    final ImageSource? selectedSource = source ?? await showImageSourceDialog();
    if (selectedSource == null) return null;

    try {
      if (kIsWeb && selectedSource == ImageSource.camera) {
        return await Get.dialog<XFile>(const WebCameraDialog());
      }

      return await _picker.pickImage(
        source: selectedSource,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se puede acceder a ${selectedSource == ImageSource.camera ? 'cámara' : 'galería'}: $e',
      );
      return null;
    }
  }

  static Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images;
    } catch (e) {
      Get.snackbar('Error', 'No se puede acceder a la galería: $e');
      return [];
    }
  }
}
