import 'package:get/get.dart';
import 'package:flutter/material.dart';

class SettingsController extends GetxController {
  // Estado de configuraciones
  var notificationsEnabled = true.obs;
  var darkModeEnabled = false.obs;
  var selectedLanguage = 'es'.obs;

  // Idiomas disponibles
  final availableLanguages = [
    {'code': 'es', 'name': 'Español'},
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'pt', 'name': 'Português'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    // TODO: Cargar configuraciones desde almacenamiento local
    // Por ahora usar valores por defecto
  }

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    saveSettings();
  }

  void toggleDarkMode(bool value) {
    darkModeEnabled.value = value;
    // Cambiar tema de la aplicación
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    saveSettings();
  }

  void changeLanguage(String? languageCode) {
    if (languageCode != null) {
      selectedLanguage.value = languageCode;
      
      // Cambiar idioma de la aplicación
      Locale locale;
      switch (languageCode) {
        case 'en':
          locale = Locale('en', 'US');
          break;
        case 'fr':
          locale = Locale('fr', 'FR');
          break;
        case 'de':
          locale = Locale('de', 'DE');
          break;
        case 'it':
          locale = Locale('it', 'IT');
          break;
        case 'pt':
          locale = Locale('pt', 'PT');
          break;
        default:
          locale = Locale('es', 'ES');
      }
      
      Get.updateLocale(locale);
      saveSettings();
    }
  }

  void logout() {
    // TODO: Implementar logout
    Get.snackbar(
      'Cerrar Sesión',
      'Sesión cerrada exitosamente',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Navegar a la pantalla de login
    Get.offAllNamed('/auth');
  }

  void saveSettings() {
    // TODO: Guardar configuraciones en almacenamiento local
    print('Settings saved');
  }
}