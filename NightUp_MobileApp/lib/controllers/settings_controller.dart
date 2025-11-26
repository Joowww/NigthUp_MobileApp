import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'auth_controller.dart';
import 'package:image_picker/image_picker.dart';

class SettingsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();
  var user = Rxn<User>();
  var isLoading = true.obs;
  var isUpdating = false.obs;
  
  // Configuraciones
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
        final response = await _apiService.get('/user/profile/${currentUser.username}');
        user.value = User.fromJson(response.data);
        print('✅ User profile loaded: ${user.value?.username}');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el perfil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    isUpdating.value = true;
    try {
      await _apiService.put('/user/profile', data: data);
      await fetchUserProfile(); // Refrescar datos
      Get.snackbar('Éxito', 'Perfil actualizado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el perfil: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> updateAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _apiService.uploadFile(
          '/user/avatar',
          filePath: image.path,
          fieldName: 'avatar',
        );
        await fetchUserProfile();
        Get.snackbar('Éxito', 'Avatar actualizado correctamente');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el avatar: $e');
    }
  }

  Future<void> updateCoverPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _apiService.uploadFile(
          '/user/cover-photo',
          filePath: image.path,
          fieldName: 'coverPhoto',
        );
        await fetchUserProfile();
        Get.snackbar('Éxito', 'Foto de portada actualizada correctamente');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la foto de portada: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.post('/user/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      Get.snackbar('Éxito', 'Contraseña actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cambiar la contraseña: $e');
    }
  }

  Future<void> updatePrivacySettings() async {
    try {
      await _apiService.put('/user/privacy-settings', data: {
        'isVisibleOnMap': isVisibleOnMap.value,
        'notificationsEnabled': notificationsEnabled.value,
      });
      Get.snackbar('Éxito', 'Configuración de privacidad actualizada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la configuración: $e');
    }
  }

  Future<void> updateLocationVisibility(bool visible) async {
    try {
      await _apiService.post('/map/location', data: {
        'isVisibleOnMap': visible,
      });
      isVisibleOnMap.value = visible;
      Get.snackbar('Éxito', 'Visibilidad en el mapa actualizada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la visibilidad: $e');
    }
  }

  void loadSettings() async {
    // Cargar configuraciones guardadas localmente
    // Esto podría venir de SharedPreferences o de tu backend
    notificationsEnabled.value = true;
    locationEnabled.value = true;
    cameraEnabled.value = true;
    darkModeEnabled.value = true;
    biometricEnabled.value = false;
    isVisibleOnMap.value = true;
  }

  void saveSettings() {
    // Guardar configuraciones localmente
    updatePrivacySettings();
  }
}