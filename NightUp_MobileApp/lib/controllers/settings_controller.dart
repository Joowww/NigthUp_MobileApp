import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/image_picker_service.dart';
import '../models/user.dart';
import 'auth_controller.dart';
import 'map_controller.dart';

class SettingsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();
  var user = Rxn<User>();
  var isLoading = true.obs;
  var isUpdating = false.obs;

  var notificationsEnabled = true.obs;
  var locationEnabled = true.obs;
  var cameraEnabled = true.obs;
  var darkModeEnabled = true.obs;
  var biometricEnabled = false.obs;
  var isVisibleOnMap = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
    loadSettings();
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;
    try {
      final currentUser = _authController.currentUser;
      if (currentUser != null) {
        final response = await _apiService.get(
          '/user/profile/${currentUser.username}',
        );
        user.value = User.fromJson(response.data);

        if (user.value != null) {
          _authController.setUser(user.value!);
          if (user.value?.isVisibleOnMap != null) {
            isVisibleOnMap.value = user.value!.isVisibleOnMap!;
          }
        }
      }
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    isUpdating.value = true;

    final oldUser = _authController.currentUser;
    if (oldUser != null) {
      final updatedJson = oldUser.toJson();
      updatedJson.addAll(data);
      _authController.setUser(User.fromJson(updatedJson));
    }

    try {
      await _apiService.put('/user/profile', data: data);

      await Future.delayed(const Duration(milliseconds: 300));

      await fetchUserProfile();
      final currentUser = _authController.currentUser;
      if (currentUser != null) {
        bool needsFix = false;
        if (data.containsKey('avatar') &&
            (currentUser.avatar == null ||
                currentUser.avatar!.contains('default'))) {
          needsFix = true;
        }
        if (data.containsKey('coverPhoto') &&
            (currentUser.coverPhoto == null ||
                currentUser.coverPhoto!.contains('default'))) {
          needsFix = true;
        }
        if (needsFix) {
          final json = currentUser.toJson();
          json.addAll(data);
          final forcedUser = User.fromJson(json);
          _authController.setUser(forcedUser);
          user.value = forcedUser;
        }
      }
    } catch (e) {
      if (oldUser != null) _authController.setUser(oldUser);
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> updateAvatar() async {
    try {
      final image = await ImagePickerService.pickImage();
      if (image != null) {
        isUpdating.value = true;
        final imageUrl = await _apiService.uploadToCloudinary(image, 'profile');
        if (imageUrl != null) {
          await updateProfile({'avatar': imageUrl});
        }
      }
    } catch (e) {
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> updateCoverPhoto() async {
    try {
      final image = await ImagePickerService.pickImage();
      if (image != null) {
        isUpdating.value = true;
        final imageUrl = await _apiService.uploadToCloudinary(image, 'covers');

        if (imageUrl != null) {
          await updateProfile({'coverPhoto': imageUrl});
        }
      }
    } catch (e) {
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _apiService.post(
        '/user/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (e) {}
  }

  Future<void> updateLocationVisibility(bool visible) async {
    final previousValue = isVisibleOnMap.value;
    isVisibleOnMap.value = visible;
    try {
      if (Get.isRegistered<MapController>()) {
        await Get.find<MapController>().setVisibilityOnMap(visible);
      } else {
        await _apiService.patch(
          '/map/visibility',
          data: {"isVisible": visible},
        );
      }

      await _apiService.put(
        '/user/privacy-settings',
        data: {
          'isVisibleOnMap': visible,
          'notificationsEnabled': notificationsEnabled.value,
        },
      );
    } catch (e) {
      isVisibleOnMap.value = previousValue;
    }
  }

  Future<void> updatePrivacySettings() async {
    await updateLocationVisibility(isVisibleOnMap.value);
  }

  void updateLocationEnabled(bool enabled) {
    locationEnabled.value = enabled;
    if (!enabled && Get.isRegistered<MapController>()) {}
    saveSettings();
  }

  void loadSettings() async {
    notificationsEnabled.value = true;
    locationEnabled.value = true;
    cameraEnabled.value = true;
    darkModeEnabled.value = true;
    biometricEnabled.value = false;
  }

  void saveSettings() {
    updateLocationVisibility(isVisibleOnMap.value);
  }

  void changeLanguage(BuildContext context, String languageCode) {
    changeLocale(context, languageCode);
    Get.updateLocale(Locale(languageCode));
    saveSettings();
  }
}
