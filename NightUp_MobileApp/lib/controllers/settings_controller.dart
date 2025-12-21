import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/image_picker_service.dart';
import '../models/user.dart';
import 'auth_controller.dart';
import '../utils/logger.dart';

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
        logger.d('User profile response: ${response.data}');
        user.value = User.fromJson(response.data);

        if (user.value != null) {
          _authController.setUser(user.value!);
        }
        logger.i('User profile successfully mapped: ${user.value?.username}');
        logger.d('Avatar URL: ${user.value?.profilePictureUrl}');
        logger.d('avatar field: ${user.value?.avatar}');
        logger.d('Cover URL: ${user.value?.coverPhoto}');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el perfil: $e');
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
      logger.i('Persistiendo en el Servidor (Plano): $data');

      final response = await _apiService.put('/user/profile', data: data);
      logger.d('Respuesta del servidor: ${response.statusCode}');

      await Future.delayed(const Duration(milliseconds: 300));

      await fetchUserProfile();

      final currentUser = _authController.currentUser;
      if (currentUser != null) {
        bool needsFix = false;

        if (data.containsKey('avatar') &&
            (currentUser.avatar == null ||
                currentUser.avatar!.contains('default')))
          needsFix = true;

        if (data.containsKey('coverPhoto') &&
            (currentUser.coverPhoto == null ||
                currentUser.coverPhoto!.contains('default')))
          needsFix = true;

        if (needsFix) {
          logger.w(
            'El servidor devolvió datos stale. Re-aplicando URLs de Cloudinary.',
          );
          final json = currentUser.toJson();
          json.addAll(data);
          final forcedUser = User.fromJson(json);
          _authController.setUser(forcedUser);
          user.value = forcedUser;
        }
      }

      Get.snackbar('Éxito', 'Perfil actualizado correctamente');
    } catch (e) {
      logger.e('Error en updateProfile: $e');
      if (oldUser != null) _authController.setUser(oldUser);
      Get.snackbar('Error', 'No se pudo sincronizar con el servidor');
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
      Get.snackbar('Error', 'No se pudo actualizar la foto de perfil: $e');
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
          Get.snackbar('Éxito', 'Foto de portada actualizada correctamente');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la portada: $e');
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
      Get.snackbar('Éxito', 'Contraseña actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cambiar la contraseña: $e');
    }
  }

  Future<void> updatePrivacySettings() async {
    try {
      await _apiService.put(
        '/user/privacy-settings',
        data: {
          'isVisibleOnMap': isVisibleOnMap.value,
          'notificationsEnabled': notificationsEnabled.value,
        },
      );
      Get.snackbar('Éxito', 'Configuración de privacidad actualizada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la configuración: $e');
    }
  }

  Future<void> updateLocationVisibility(bool visible) async {
    try {
      await _apiService.post(
        '/map/location',
        data: {'isVisibleOnMap': visible},
      );
      isVisibleOnMap.value = visible;
      Get.snackbar('Éxito', 'Visibilidad en el mapa actualizada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la visibilidad: $e');
    }
  }

  void loadSettings() async {
    notificationsEnabled.value = true;
    locationEnabled.value = true;
    cameraEnabled.value = true;
    darkModeEnabled.value = true;
    biometricEnabled.value = false;
    isVisibleOnMap.value = true;
  }

  void saveSettings() {
    updatePrivacySettings();
  }
}
