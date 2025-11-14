import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        elevation: 0,
      ),
      body: Obx(() => ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Perfil'),
                  subtitle: Text('Editar información personal'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Get.toNamed('/edit-profile'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Cambiar Contraseña'),
                  subtitle: Text('Actualizar contraseña de acceso'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Get.toNamed('/change-password'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notificaciones'),
                  subtitle: Text('Configurar alertas y avisos'),
                  trailing: Switch(
                    value: controller.notificationsEnabled.value,
                    onChanged: controller.toggleNotifications,
                  ),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.dark_mode),
                  title: Text('Modo Oscuro'),
                  subtitle: Text('Cambiar apariencia de la aplicación'),
                  trailing: Switch(
                    value: controller.darkModeEnabled.value,
                    onChanged: controller.toggleDarkMode,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Idioma'),
                  subtitle: Text('Cambiar idioma de la aplicación'),
                  trailing: DropdownButton<String>(
                    value: controller.selectedLanguage.value,
                    underline: Container(),
                    items: controller.availableLanguages.map<DropdownMenuItem<String>>((language) {
                      return DropdownMenuItem<String>(
                        value: language['code'] as String,
                        child: Text(language['name'] as String),
                      );
                    }).toList(),
                    onChanged: controller.changeLanguage,
                  ),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.security),
                  title: Text('Privacidad'),
                  subtitle: Text('Gestionar datos personales'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Mostrar información de privacidad
                    Get.dialog(
                      AlertDialog(
                        title: Text('Privacidad'),
                        content: Text('Configuración de privacidad y protección de datos.'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Acerca de'),
                  subtitle: Text('Información de la aplicación'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Get.dialog(
                      AlertDialog(
                        title: Text('NightUp v1.0.0'),
                        content: Text('Aplicación para descubrir eventos nocturnos y conectar con negocios locales.'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  subtitle: Text('Salir de la aplicación'),
                  onTap: () {
                    Get.dialog(
                      AlertDialog(
                        title: Text('Cerrar Sesión'),
                        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              controller.logout();
                            },
                            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}